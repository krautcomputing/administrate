require_relative "associative"

module Administrate
  module Field
    class HasOne < Associative
      def nested_form
        super(data || resolver.resource_class.new)
      end

      def self.permitted_attribute(attr, options)
        if options[:ignore_related_dashboard_attributes]
          {}
        else
          resolver = Administrate::ResourceResolver.new("admin/#{options[:class_name] || attr}")
          related_dashboard_attributes = resolver.dashboard_class.new.permitted_attributes(options.merge(ignore_related_dashboard_attributes: true)) + [:id]
          { "#{attr}_attributes": related_dashboard_attributes }
        end
      end
    end
  end
end
