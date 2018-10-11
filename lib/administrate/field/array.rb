require_relative "base"

module Administrate
  module Field
    class Array < Base
      def self.permitted_attribute(attr, *)
        [attr, attr => []]
      end
    end
  end
end
