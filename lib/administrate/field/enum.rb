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

      def only_a_few_options
        display_options_and_keys.size <= 3
      end

      def radio_buttons
        if options.key?(:radio_buttons)
          options[:radio_buttons]
        else
          only_a_few_options
        end
      end

      def radio_buttons_inline
        if options.key?(:radio_buttons_inline)
          options[:radio_buttons_inline]
        else
          only_a_few_options
        end
      end
    end
  end
end
