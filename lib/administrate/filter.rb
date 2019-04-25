module Administrate
  class Filter
    include ActiveModel::Model

    attr_reader :key
    attr_accessor :value, :label, :kind, :action, :values

    class << self
      def all(dashboard)
        dashboard.filters.map do |key, details|
          values = details.fetch(:values).map do |value|
            value_key, value_label = if value.is_a?(Array)
              value
            else
              [value, value.to_s.humanize]
            end
            Value.new(key: value_key, label: value_label)
          end
          new(key:    key,
              label:  details[:label] || key.to_s.humanize,
              kind:   details.fetch(:kind),
              values: values,
              action: details[:action]
          )
        end.unshift(new(key: :search))
      end

      def apply(resource_resolver, filters)
        resource_class = resource_resolver.resource_class
        relation       = resource_class.all
        filters.each do |filter|
          relation = case
          when filter.key == :search
            unless resource_class.respond_to?(:internal_search)
              # Find fields that are searchable and not globalized.
              search_attrs = resource_resolver.dashboard_class::ATTRIBUTE_TYPES.select do |_, type|
                type.searchable? &&
                !(type.is_a?(Administrate::Field::Deferred) && type.options[:globalize])
              end.keys

              # Select fields that are db columns.
              column_search_attrs = search_attrs.select { |attr| resource_class.column_names.include?(attr.to_s) }
              if column_search_attrs.none?
                raise 'Could not find any column search attributes.'
              end

              pg_search_params = {
                against: column_search_attrs
              }

              # Select fields that are associations.
              association_search_attrs = search_attrs.select { |attr| resource_class.reflections.include?(attr.to_s) }
              if association_search_attrs.any?
                pg_search_params[:associated_against] = association_search_attrs.each_with_object({}) do |association_name, hash|
                  # Find fields of association that are searchable, not globalized and db columns.
                  relation_resource_resolver = Administrate::ResourceResolver.new("admin/#{association_name.to_s.pluralize}")
                  relation_search_attrs = relation_resource_resolver.dashboard_class::ATTRIBUTE_TYPES.select do |attr, type|
                    type.searchable? &&
                    !(type.is_a?(Administrate::Field::Deferred) && type.options[:globalize]) &&
                    relation_resource_resolver.resource_class.column_names.include?(attr.to_s)
                  end.keys
                  hash[association_name] = relation_search_attrs
                end
              end

              # Define search scope.
              resource_class.pg_search_scope :internal_search, pg_search_params
            end
            relation.where(id: resource_class.internal_search(filter.value.key.to_s))
          when filter.action
            filter.instance_exec(relation, &filter.action)
          else
            dashboard = resource_resolver.dashboard_class.new
            unless default_filter_action = dashboard.method(:default_filter_action)
              fail "Dashboard #{dashboard.class} doesn't define a default filter action, which is needed because filter #{filter.key} doesn't have an action."
            end
            default_filter_action.call(relation, filter.key, filter.value)
          end
        end
        relation.distinct
      end
    end

    def key=(key)
      @key = key.to_sym
    end

    def value=(value)
      @value = case value
      when Array
        value.select(&:present?).map do |v|
          v =~ /\A\d+\z/ ? v.to_i : v.to_sym
        end
      when /\A\d+\z/
        value.to_i
      else
        if key == :search
          value
        else
          value.to_sym
        end
      end
    end

    def value
      if key == :search
        Value.new(key: @value || '', label: @value || '')
      else
        value_array = Array(@value).map do |value|
          value_from_values = values.detect do |v|
            if v.key.is_a?(Proc)
              v.key.call(value)
            else
              v.key == value
            end
          end
          unless value_from_values
            fail %(Could not find "#{value}" in values for filter "#{key}".)
          end
          Value.new(key: value, label: value_from_values.label)
        end
        if @value.is_a?(Array)
          value_array
        else
          value_array.first
        end
      end
    end

    class Value
      include ActiveModel::Model

      attr_accessor :key, :label

      def to_s
        if label.is_a?(Proc)
          label.call(key)
        else
          label.to_s
        end
      end
    end

    class Finder
      def initialize(resource_resolver, key)
        @dashboard = resource_resolver.dashboard_class.new
        @key = key
      end

      def find
        Filter.all(@dashboard).detect { |filter| filter.key == @key.to_sym } or fail "Cannot find filter with key #{@key}."
      end

      def find_and_assign_value(value)
        find.tap do |filter|
          filter.value = value
        end
      end
    end
  end
end
