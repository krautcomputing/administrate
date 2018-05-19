require_relative "associative"

module Administrate
  module Field
    class HasOne < Associative
      def nested_form
        @nested_form ||= Administrate::Page::Form.new(
          resolver.dashboard_class.new,
          data || resolver.resource_class.new,
        )
      end

      def self.permitted_attribute(attr, action)
        related_dashboard_attributes =
          Administrate::ResourceResolver.new("admin/#{attr}").
            dashboard_class.new.permitted_attributes(action) + [:id]

        { "#{attr}_attributes": related_dashboard_attributes }
      end

      private

      def resolver
        @resolver ||=
          Administrate::ResourceResolver.new("admin/#{associated_class_name}")
      end
    end
  end
end
