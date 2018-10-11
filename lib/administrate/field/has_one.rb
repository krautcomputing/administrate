require_relative "associative"

module Administrate
  module Field
    class HasOne < Associative
      def nested_form
        super(data || resolver.resource_class.new)
      end

      def self.permitted_attribute(attr, action)
        related_dashboard_attributes =
          Administrate::ResourceResolver.new("admin/#{attr}").
            dashboard_class.new.permitted_attributes(action) + [:id]

        { "#{attr}_attributes": related_dashboard_attributes }
      end
    end
  end
end
