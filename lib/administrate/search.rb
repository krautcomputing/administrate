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
        condition_parts = []
        condition_params = { query: "%#{@term}%" }
        search_attributes.each do |attribute|
          next unless table_name = table_name(attribute)
          attribute_with_table_name = "#{table_name}.#{attribute}"
          column = resource_class.columns_hash[attribute.to_s] || (resource_class.acting_as? && resource_class.acting_as_model.columns_hash[attribute.to_s])
          case
          when column.type == :integer && enum = resource_class.defined_enums[attribute.to_s]
            enum_values = enum.select { |k, _| k =~ /#{Regexp.escape(@term)}/i }
            if enum_values.any?
              condition_param = "#{attribute}_enum_keys".to_sym
              condition_parts << "#{attribute_with_table_name} IN (:#{condition_param})"
              condition_params[condition_param] = enum_values.values
            end
          when column.array
            # Find IDs of records that contain the query in the column array.
            # Use a subquery and `array_to_string` so we can us ILIKE.
            list_column = "#{attribute}_list"
            if resource_class.acting_as? && resource_class.acting_as_model.attribute_method?(attribute)
              acting_as_ids = resource_class.acting_as_model.
                      select("#{resource_class.acting_as_model.table_name}.id").
                      from("#{resource_class.acting_as_model.table_name}, array_to_string(#{attribute_with_table_name}, ',') AS #{list_column}").
                      where("#{list_column} ILIKE ?", "%#{@term}%")
              ids = resource_class.
                      joins(resource_class.acting_as_name.to_sym).
                      select("#{resource_class.table_name}.id").
                      where("#{resource_class.acting_as_model.table_name}.id IN (?)", acting_as_ids).
                      map(&:id)
            else
              ids = resource_class.
                      select("#{resource_class.table_name}.id").
                      from("#{resource_class.table_name}, array_to_string(#{attribute_with_table_name}, ',') AS #{list_column}").
                      where("#{list_column} ILIKE ?", "%#{@term}%").
                      map(&:id)
            end
            condition_param = "#{attribute}_ids".to_sym
            condition_parts << "#{resource_class.table_name}.id IN (:#{condition_param})"
            condition_params[condition_param] = ids
          else
            condition_parts << "#{attribute_with_table_name} ILIKE :query"
          end
        end
        if @search_relations
          # Create a resolver and search for each search relation.
          # Find only the IDs for each search relation and add them
          # as a condition part.
          search_relations.each do |search_relation|
            search_relation_resolver = Administrate::ResourceResolver.new("admin/#{search_relation.to_s.pluralize}")
            search = self.class.new(search_relation_resolver, @term, false)
            ids = search.run.ids
            if ids.any?
              condition_param = "#{search_relation}_ids".to_sym
              condition_parts << "#{search_relation_resolver.resource_class.table_name}.id IN (:#{condition_param})"
              condition_params[condition_param] = ids

              # Let's see what kind of association we're dealing with.
              field_class = if attribute_types[search_relation].is_a?(Administrate::Field::Deferred)
                attribute_types[search_relation].deferred_class
              else
                attribute_types[search_relation].class
              end
              foreign_key = resource_class.reflections[search_relation.to_s].foreign_key
              primary_key = 'id'
              resource_column, search_resource_column = case field_class.to_s
              when 'Administrate::Field::BelongsTo' then [foreign_key, primary_key]
              when 'Administrate::Field::HasMany'   then [primary_key, foreign_key]
              else fail "Unexpected field class: #{field_class}"
              end

              # TODO: In Rails 5, we can use #left_outer_joins
              # http://blog.bigbinary.com/2016/03/24/support-for-left-outer-joins-in-rails-5.html
              relation.joins!("
                LEFT OUTER JOIN #{search_relation_resolver.resource_class.table_name}
                  ON #{resource_class.table_name}.#{resource_column} =
                     #{search_relation_resolver.resource_class.table_name}.#{search_resource_column}".gsub(/\s+/, ' '))
            end
          end
        end
        relation.where!(condition_parts.join(' OR '), condition_params)
      end
      relation
    end

    private

    delegate :resource_class, to: :resolver

    def table_name(attribute)
      if resource_class.acting_as? && resource_class.acting_as_model.column_names.include?(attribute.to_s)
        resource_class.acting_as_model.table_name
      elsif resource_class.column_names.include?(attribute.to_s)
        resource_class.table_name
      end
    end

    def attribute_types
      resolver.dashboard_class::ATTRIBUTE_TYPES
    end

    attr_reader :resolver, :term
  end
end
