require_relative "associative"

module Administrate
  module Field
    class BelongsTo < Associative
      def self.permitted_attribute(attr, *)
        :"#{attr}_id"
      end

      def permitted_attribute
        foreign_key
      end

      def associated_resource_options
        [nil] + super
      end

      def selected_option
        data && data.send(primary_key)
      end
    end
  end
end
