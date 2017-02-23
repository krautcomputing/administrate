require_relative "base"

module Administrate
  module Field
    class Alpha < Base
      def self.searchable?
        true
      end

      def globalize?
        options[:globalize]
      end

      def truncate
        data.to_s[0...truncation_length]
      end

      private

      def truncation_length
        options.fetch(:truncate, 50)
      end
    end
  end
end
