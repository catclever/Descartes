require_relative 'context'
require_relative 'orchestration/job'
require 'logger'

module Amber
  class Engine
    attr_reader :context, :jobs

    def self.build(&block)
      engine = new
      engine.instance_eval(&block) if block_given?
      engine
    end

    def initialize
      @context = Context.new
      @jobs = {}
      @logger = Logger.new($stdout)
      @logger.level = Logger::INFO
    end

    # DSL: Initialize the starting state of context
    def environment(hash)
      @context.merge(hash)
    end

    # DSL: Define a job
    def job(name, &block)
      j = Orchestration::Job.new(name)
      # evaluate the job DSL methods (action, depends_on, etc.) within the context of the Job instance
      j.instance_eval(&block) if block_given?
      @jobs[name.to_sym] = j
    end

    # Execution Entrypoint
    def run!
      @logger.info "[Amber] Starting Engine with #{@jobs.size} defined jobs."
      
      # For now, we use a simple synchronous polling loop to simulate parallelism and waiting.
      # In future iterations, this will be swapped to truly concurrent threaded execution.
      
      loop do
        pending_jobs = @jobs.values.select { |j| j.status == :pending }
        running_jobs = @jobs.values.select { |j| j.status == :running }
        completed_jobs = @jobs.values.select { |j| %i[completed failed].include?(j.status) }

        break if pending_jobs.empty? && running_jobs.empty?

        # Find any pending jobs whose dependencies are met
        ready_jobs = pending_jobs.select do |j|
          dependencies_met?(j, completed_jobs)
        end

        if ready_jobs.empty? && running_jobs.empty?
          @logger.error "[Amber] DEADLOCK: No jobs are running and no pending jobs have their dependencies met. Terminating."
          break
        end

        # Dispatch ready jobs (simulated sequence for now)
        ready_jobs.each do |j|
          @logger.info "[Amber] Dispatching Job: :#{j.name}"
          
          # In true parallel form, this would be wrapped in a Thread.new or Async block
          j.execute!(@context)
          
          @logger.info "[Amber] Finished Job: :#{j.name} with status: #{j.status}"
        end

        # Sleep to prevent tight spin-loop while waiting for threaded jobs
        sleep(0.1) unless ready_jobs.any?
      end

      @logger.info "[Amber] Engine Run Complete. Final Context: #{@context.snapshot.inspect}"
    end

    private

    def dependencies_met?(job, completed_jobs)
      # 1. Check formal dependencies
      formal_met = job.formal_dependencies.all? do |dep_name|
        completed_jobs.any? { |cj| cj.name == dep_name && cj.status == :completed }
      end
      return false unless formal_met

      # 2. Check Semantic (AI) dependencies
      # TODO: Call ruby_llm to evaluate the context snapshot against the job.ai_dependencies array.
      # For now, if there are AI dependencies, we pretend they instantly pass for skeleton purpose.
      true
    end
  end
end
