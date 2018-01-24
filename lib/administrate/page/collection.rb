require_relative "base"

module Administrate
  module Page
    class Collection < Page::Base
      def attribute_names
        dashboard.collection_attributes
      end

      def fields_for(resource)
        attribute_names.map do |attribute|
          field resource, attribute
        end
      end

      def field(resource, attribute)
        attribute_field(dashboard, resource, attribute, :index)
      end

      def attribute_types
        dashboard.attribute_types_for(attribute_names)
      end

      def ordered_html_class(attr)
        ordered_by?(attr) && order.direction
      end

      delegate :ordered_by?, :order_params_for, to: :order
      delegate :resource_html_class, :resource_actions, :collection_actions, to: :dashboard

      private

      def order
        options[:order] || Order.new
      end
    end
  end
end
