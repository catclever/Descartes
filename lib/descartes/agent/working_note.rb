module Descartes
  module Agent
    class WorkingNote
      def initialize
        @notes = {}
      end

      # Set a scratchpad variable local only to the running agent
      def set_note(key, value)
        @notes[key.to_sym] = value
      end

      # Retrieve a scratchpad variable
      def get_note(key)
        @notes[key.to_sym]
      end

      # Check if notes are empty
      def empty?
        @notes.empty?
      end

      # Returns the full state of the working notes for potential context injection
      def dump
        @notes.dup
      end
    end
  end
end
