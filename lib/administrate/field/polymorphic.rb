require_relative "associative"

module Administrate
  module Field
    class Polymorphic < BelongsTo
      def associated_resource_options
        resources_to_options = ->(resources) {
          resources.map do |resource|
            [display_candidate_resource(resource), resource.to_global_id]
          end
        }
        case
        when candidate_resources = options[:candidate_resources]
          candidate_resources.call(resource).transform_values(&resources_to_options.method(:call))
        when classes = options[:classes]
          classes.map do |klass|
            [
              klass.to_s,
              resources_to_options.call(candidate_resources_for(klass))
            ]
          end
        else raise "Cannot determine associated resource options for polymorphic field #{self}."
        end
      end

      def self.permitted_attribute(attr, *)
        { attr => %i{type value} }
      end

      def permitted_attribute
        { attribute => %i{type value} }
      end

      def selected_global_id
        data ? data.to_global_id : nil
      end

      protected

      def associated_dashboard(klass = data.class)
        "#{klass.name}Dashboard".constantize.new
      end

      private

      def order
        @_order ||= options.delete(:order)
      end

      def candidate_resources_for(klass)
        order ? klass.order(order) : klass.all
      end

      def display_candidate_resource(resource)
        associated_dashboard(resource.class).display_resource(resource)
      end
    end
  end
end
