# frozen_string_literal: true

module Descartes
  module EventEmitter
    # Register an event listener.
    # @param event [Symbol] The event name (default: :all).
    # @param block [Proc] The callback to execute when the event is emitted.
    def on(event = :all, &block)
      _event_mutex.synchronize do
        @_event_listeners ||= {}
        @_event_listeners[event] ||= []
        @_event_listeners[event] << block
      end
      self
    end

    # Emit an event to all registered listeners.
    # @param event [Symbol] The event name.
    # @param payload [Object] The payload to pass to the callbacks.
    def emit(event, payload = nil)
      listeners_to_call = []
      _event_mutex.synchronize do
        return unless defined?(@_event_listeners) && @_event_listeners

        listeners_to_call += @_event_listeners[event] || []
        listeners_to_call += @_event_listeners[:all] || []
      end

      listeners_to_call.each do |block|
        if block.arity.zero?
          block.call
        elsif block.arity == 1
          block.call(payload)
        else
          block.call(event, payload)
        end
      rescue StandardError => e
        # Optionally log the error, but we shouldn't crash the emission loop
        # unless it's a specific requirement. For now we rescue and ignore or log if logger available
        @logger.error "[EventEmitter] Error in callback for event #{event}: #{e.message}" if defined?(@logger) && @logger
      end
    end

    private

    def _event_mutex
      @_event_mutex ||= Mutex.new
    end
  end
end
