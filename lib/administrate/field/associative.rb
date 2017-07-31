require_relative "base"

module Administrate
  module Field
    class Associative < Base
      def display_associated_resource
        display_candidate_resource data
      end

      protected

      def associated_dashboard
        "#{associated_class_name}Dashboard".safe_constantize.try(:new)
      end

      def associated_class
        associated_class_name.constantize
      end

      def associated_class_name
        options.fetch(:class_name, attribute.to_s.singularize.camelcase)
      end

      def candidate_resources
        case
        when custom_candidate_resources = options[:candidate_resources]
          custom_candidate_resources.call resource
        when includes = options[:includes]
          associated_class.includes(*includes).all
        else
          associated_class.all
        end
      end

      def display_candidate_resource(resource)
        if custom_display_candidate_resource = options[:display_candidate_resource]
          custom_display_candidate_resource.call resource
        else
          associated_dashboard.display_resource resource
        end
      end

      def primary_key
        options.fetch(:primary_key, :id)
      end

      def foreign_key
        options.fetch(:foreign_key, :"#{attribute}_id")
      end
    end
  end
end
