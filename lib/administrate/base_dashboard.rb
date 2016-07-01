require "administrate/field/belongs_to"
require "administrate/field/boolean"
require "administrate/field/date_time"
require "administrate/field/email"
require "administrate/field/has_many"
require "administrate/field/has_one"
require "administrate/field/number"
require "administrate/field/polymorphic"
require "administrate/field/select"
require "administrate/field/string"
require "administrate/field/text"

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
        attribute_types[attr].permitted_attribute(attr)
      end.uniq
    end

    def show_page_attributes
      self.class::SHOW_PAGE_ATTRIBUTES
    end

    def collection_attributes
      self.class::COLLECTION_ATTRIBUTES
    end

    def display_resource(resource)
      "#{resource.class} ##{resource.id}"
    end

    # Override this method in your dashboard
    # to add a class to each resource row in the table.
    def resource_html_class(resource)
    end

    private

    def attribute_not_found_message(attr)
      "Attribute #{attr} could not be found in #{self.class}::ATTRIBUTE_TYPES"
    end

    def const_not_found_message(candidates)
      "None of the form attributes constants could be found on #{self.class}: #{candidates.join(', ')}"
    end
  end
end
