# frozen_string_literal: true

require "json"
require "fileutils"

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

      # Export the working notes to a JSON file
      def export_to_file(file_path)
        dir = File.dirname(file_path)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

        File.write(file_path, JSON.pretty_generate(@notes))
      end

      # Import the working notes from a JSON file
      # This will merge the imported notes with the existing ones
      def import_from_file(file_path)
        return false unless File.exist?(file_path)

        data = JSON.parse(File.read(file_path))
        data.each do |k, v|
          @notes[k.to_sym] = v
        end
        true
      rescue JSON::ParserError
        false
      end
    end
  end
end
