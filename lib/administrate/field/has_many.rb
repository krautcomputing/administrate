require_relative "associative"
require "administrate/page/collection"

module Administrate
  module Field
    class HasMany < Associative
      DEFAULT_LIMIT = 5

      def self.permitted_attribute(attribute)
        { "#{attribute.to_s.singularize}_ids".to_sym => [] }
      end

      def associated_collection
        Administrate::Page::Collection.new(associated_dashboard)
      end

      def attribute_key
        permitted_attribute.keys.first
      end

      def associated_resource_options
        candidate_resources.map do |resource|
          [display_candidate_resource(resource), resource.send(primary_key)]
        end
      end

      def selected_options
        data && data.map { |object| object.send(primary_key) }
      end

      def limit
        options.fetch(:limit, DEFAULT_LIMIT)
      end

      def permitted_attribute
        self.class.permitted_attribute(attribute)
      end

      def resources
        data.limit(limit)
      end

      def more_than_limit?
        data.count(:all) > limit
      end

      private

      def candidate_resources
        if options.key?(:includes)
          includes = options.fetch(:includes)
          associated_class.includes(*includes).all
        else
          associated_class.all
        end
      end

      def display_candidate_resource(resource)
        associated_dashboard.try(:display_resource, resource) || resource.to_s
      end
    end
  end
end
