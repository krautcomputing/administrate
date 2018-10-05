require "administrate/field/array"
require "administrate/field/attachment"
require "administrate/field/belongs_to"
require "administrate/field/boolean"
require "administrate/field/date_time"
require "administrate/field/date"
require "administrate/field/email"
require "administrate/field/enum"
require "administrate/field/has_many"
require "administrate/field/has_one"
require "administrate/field/number"
require "administrate/field/polymorphic"
require "administrate/field/select"
require "administrate/field/string"
require "administrate/field/text"
require "administrate/field/link"

module Administrate
  class BaseDashboard
    include Administrate

    FORM_ATTRIBUTE_ACTION_ALIASES = {
      create: 'new',
      update: 'edit'
    }.freeze

    def attribute_types
      self.class::ATTRIBUTE_TYPES
    end

    def attribute_type_for(attribute_name)
      attribute_types.fetch(attribute_name) do
        fail attribute_not_found_message(attribute_name)
      end
    end

    def attribute_types_for(attribute_names)
      attribute_names.each_with_object({}) do |name, attributes|
        attributes[name] = attribute_type_for(name)
      end
    end

    def form_attributes(action)
      const_candidates = [:"#{action.upcase}_FORM_ATTRIBUTES"]
      if action_alias = FORM_ATTRIBUTE_ACTION_ALIASES[action.to_sym]
        const_candidates << :"#{action_alias.upcase}_FORM_ATTRIBUTES"
      end
      const_candidates << :FORM_ATTRIBUTES
      const = const_candidates.detect do |const_candidate|
        self.class.const_defined?(const_candidate)
      end
      unless const
        fail const_not_found_message(const_candidates)
      end
      self.class.const_get(const)
    end

    def permitted_attributes(action)
      form_attributes(action).map do |attr|
        attribute_types[attr].permitted_attribute(attr, action)
      end.uniq
    end

    def show_page_attributes
      self.class::SHOW_PAGE_ATTRIBUTES
    end

    def collection_attributes
      self.class::COLLECTION_ATTRIBUTES
    end

    def display_resource(resource)
      resource.to_s
    end

    # Override this method in your dashboard
    # to add a class to each resource row in the table.
    def resource_html_class(resource)
    end

    # Override this method in your dashboard
    # to add custom resource actions.
    def resource_actions(resource, params)
      []
    end

    # Override this method in your dashboard
    # to add custom collection actions.
    def collection_actions
      []
    end

    def filters
      {}
    end

    def association_includes
      collection_attributes.select do |key|
        field = attribute_types[key]
        next if field.respond_to?(:options) && field.options.key?(:include) && !field.options[:include]
        association_classes.include?(field) || (field.respond_to?(:deferred_class) && association_classes.include?(field.deferred_class))
      end
    end

    private

    def attribute_not_found_message(attr)
      "Attribute #{attr} could not be found in #{self.class}::ATTRIBUTE_TYPES"
    end

    def const_not_found_message(candidates)
      "None of the form attributes constants could be found on #{self.class}: #{candidates.join(', ')}"
    end

    def association_classes
      @association_classes ||=
        ObjectSpace.each_object(Class).
          select { |klass| klass < Administrate::Field::Associative }
    end
  end
end
