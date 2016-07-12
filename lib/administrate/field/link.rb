require_relative "base"

module Administrate
  module Field
    class Link < Field::Base
      def self.searchable?
        true
      end
    end
  end
end
