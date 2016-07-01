require "active_support/core_ext/module/delegation"
require "active_support/core_ext/object/blank"

module Administrate
  class Search
    def initialize(resolver, term, search_relations = true)
      @resolver = resolver
      @term = term
      @search_relations = search_relations
    end

    def run
      relation = resource_class.all
      if @term.present?
        # Find searchable attributes and relations.
        search_relations, search_attributes = attribute_types.keys.select do |attribute|
          attribute_types[attribute].searchable?
        end.partition do |attribute|
          resource_class.reflections.keys.include?(attribute.to_s)
        end
        # Join with acting_as class if any attributes from that class are searchable.
        if resource_class.acting_as? && search_attributes.any? { |attribute| resource_class.acting_as_model.attribute_method?(attribute) }
          relation.joins!(resource_class.acting_as_name.to_sym)
        end
        # Set up condition parts and params
        condition_parts = search_attributes.map { |attribute| "LOWER(#{table_name(attribute)}.#{attribute}) LIKE :query" }
        condition_params = { query: "%#{@term.downcase}%" }
        if @search_relations
          # Create a resolver and search for each search relation.
          # Find only the IDs for each search relation and add them
          # as a condition part.
          search_relations.each do |search_relation|
            resolver = Administrate::ResourceResolver.new("admin/#{search_relation}")
            search = self.class.new(resolver, @term, false)
            condition_param = "#{search_relation}_ids".to_sym
            condition_parts << "#{resolver.resource_class.table_name}.id IN (:#{condition_param})"
            condition_params[condition_param] = search.run.ids
            relation.joins!(resolver.resource_class.table_name.to_sym)
          end
        end
        relation.where!(condition_parts.join(' OR '), condition_params)
      end
      relation
    end

    private

    delegate :resource_class, to: :resolver

    def table_name(attribute)
      if resource_class.acting_as? && resource_class.acting_as_model.attribute_method?(attribute)
        resource_class.acting_as_model.table_name
      else
        resource_class.table_name
      end
    end

    def attribute_types
      resolver.dashboard_class::ATTRIBUTE_TYPES
    end

    attr_reader :resolver, :term
  end
end
