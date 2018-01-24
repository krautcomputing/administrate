require_relative "base"

module Administrate
  module Field
    class Enum < Field::Base
      def options
        resource.class.public_send(attribute.to_s.pluralize).keys.map { |key| [key.titleize, key] }
      end
    end
  end
end
