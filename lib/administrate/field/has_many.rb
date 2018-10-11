require_relative "associative"
require "administrate/page/collection"
require "administrate/order"

module Administrate
  module Field
    class HasMany < Associative
      DEFAULT_LIMIT = 5

      def self.permitted_attribute(attr, options)
        related_dashboard_attributes = Administrate::ResourceResolver.new("admin/#{options[:class_name] || attr}").dashboard_class.new.permitted_attributes(options[:action]) + [:id]
        {
          "#{attr}_attributes":           related_dashboard_attributes,
          "#{attr.to_s.singularize}_ids": []
        }
      end

      def associated_collection
        Administrate::Page::Collection.new(associated_dashboard)
      end

      def attribute_key
        "#{attribute.to_s.singularize}_ids"
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

      def nested?
        !!options[:nested]
      end

      def permitted_attribute
        self.class.permitted_attribute(attribute, options)
      end

      def resources(page = nil)
        resources = order.apply(data)
        resources = resources.page(page).per(limit) if page
        resources = resources.includes(*includes) if includes.any?
        resources
      end

      def more_than_limit?
        data.count(:all) > limit
      end

      private

      def includes
        associated_dashboard.association_includes
      end

      def order
        @_order ||= Administrate::Order.new(sort_by, direction)
      end

      def sort_by
        options[:sort_by]
      end

      def direction
        options[:direction]
      end
    end
  end
end
