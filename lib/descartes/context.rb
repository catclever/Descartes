module Descartes
  class Context
    attr_reader :state

    def initialize(initial_state = {})
      @state = initial_state
      @mutex = Mutex.new
    end

    def get(*keys)
      @mutex.synchronize do
        # Access nested keys using an array, e.g., get(:user, :name)
        keys.reduce(@state) { |hash, key| hash.is_a?(Hash) ? hash[key.to_sym] : nil }
      end
    end

    def set(key, value)
      @mutex.synchronize do
        @state[key.to_sym] = value
      end
    end

    # Bulk merge into the state
    def merge(hash)
      @mutex.synchronize do
        @state.merge!(hash)
      end
    end

    # Read-only snapshot of current state
    def snapshot
      @mutex.synchronize { @state.dup }
    end
  end
end
