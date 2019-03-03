require_relative "base"

module Administrate
  module Page
    class Show < Page::Base
      def initialize(dashboard, resource)
        super(dashboard)
        @resource = resource
      end

      attr_reader :resource

      def page_title
        dashboard.display_resource(resource)
      end

      def attributes(_)
        dashboard.show_page_attributes.map do |attr_name|
          attribute_field(dashboard, resource, attr_name, :show)
        end
      end

      def resource_actions(params)
        dashboard.resource_actions(resource, params)
      end
    end
  end
end
