# frozen_string_literal: true

require "English"
require "tmpdir"
require "timeout"

module Descartes
  module Sandbox
    class Executor
      class Error < StandardError; end
      class TimeoutError < Error; end
      class SecurityError < Error; end
      class ExecutionError < Error; end

      def initialize(memory_limit_mb: 200, cpu_limit_sec: 5)
        @memory_limit_mb = memory_limit_mb
        @cpu_limit_sec = cpu_limit_sec
      end

      def execute(code)
        validate_ast!(code)

        Dir.mktmpdir("descartes_workspace_") do |workspace_dir|
          run_in_subprocess(code, workspace_dir)
        end
      end

      private

      def validate_ast!(code)
        # Parse the code to ensure there are no explicitly blocked method calls
        ast = RubyVM::AbstractSyntaxTree.parse(code)
        check_node(ast)
      rescue SyntaxError => e
        raise ExecutionError, "Syntax error in provided code: #{e.message}"
      end

      FORBIDDEN_METHODS = %i[system exec spawn fork syscall ` setrlimit exit exit! abort].freeze

      def check_node(node)
        return unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)

        if %i[FCALL VCALL CALL].include?(node.type)
          # For CALL nodes, the method name is typically the second object
          method_name = node.type == :CALL ? node.children[1] : node.children[0]

          raise SecurityError, "Forbidden method call detected: #{method_name}" if FORBIDDEN_METHODS.include?(method_name)
        elsif node.type == :XSTR # Backticks `ls`
          raise SecurityError, "Backtick (system command) execution is forbidden."
        end

        node.children.each do |child|
          check_node(child)
        end
      end

      def run_in_subprocess(code, workspace_dir)
        reader, writer = IO.pipe

        pid = Process.fork do
          reader.close

          begin
            # Apply resource limits
            if Process.respond_to?(:setrlimit)
              # CPU limits in seconds
              Process.setrlimit(Process::RLIMIT_CPU, @cpu_limit_sec)

              # Memory limit in bytes (Address space)
              begin
                Process.setrlimit(Process::RLIMIT_AS, @memory_limit_mb * 1024 * 1024)
              rescue StandardError, NotImplementedError
                # skip if not supported or fails on OS
              end
            end

            # Wipe environment variables to prevent token leakage
            ENV.clear

            # Change to isolated tmp workspace
            Dir.chdir(workspace_dir)

            result = eval(code, binding, "descartes_sandbox", 1)

            payload = Marshal.dump({ status: :success, result: result })
            writer.write(payload)
          rescue Exception => e
            payload = Marshal.dump({ status: :error, class: e.class.name, message: e.message, backtrace: e.backtrace })
            writer.write(payload)
          ensure
            writer.close
            exit!(0)
          end
        end

        writer.close

        begin
          Timeout.timeout(@cpu_limit_sec + 2) do
            Process.wait(pid)
          end
        rescue Timeout::Error
          Process.kill("KILL", pid)
          Process.wait(pid)
          raise TimeoutError, "Sandbox execution timed out after #{@cpu_limit_sec} seconds."
        end

        output = reader.read
        reader.close

        if $CHILD_STATUS.exited? && $CHILD_STATUS.exitstatus.zero?
          return nil if output.empty?

          # Safely load the payload
          data = Marshal.load(output)
          raise ExecutionError, "#{data[:class]}: #{data[:message]}\n" + Array(data[:backtrace]).join("\n") unless data[:status] == :success

          data[:result]

        else
          raise TimeoutError, "Sandbox execution timed out (CPU limit exceeded)." if [24,
                                                                                      9].include?($CHILD_STATUS.termsig)

          raise ExecutionError, "Subprocess crashed or was killed by signal: #{$CHILD_STATUS.termsig}"

        end
      end
    end
  end
end
