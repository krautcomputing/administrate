require_relative "base"

module Administrate
  module Field
    class Enum < Field::Base
      def display_options_and_keys
        resource.class.public_send(attribute.to_s.pluralize).keys.map { |key| [display_option(key), key] }
      end

      def display_option(option = data)
        case
        when custom_display_option = options[:display_option]
          custom_display_option.call option
        when option.present?
          option.humanize
        else
          '-'
        end
      end
    end
  end
end
