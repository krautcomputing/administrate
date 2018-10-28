module Administrate
  module ApplicationHelper
    def page_html_class
      "#{params[:controller].split('/').last} #{params[:action]}"
    end

    def render_field(field, locals = {})
      if !(partial = field_partial(field)) && field.page == :show && !(partial = field_partial(field, :index))
        raise "Could not find partial for field #{field}."
      end

      render partial: partial, locals: locals.merge(field: field)
    end

    def render_custom_fields(resource, action, locals = {})
      case action
      when 'create' then action = 'new'
      when 'update' then action = 'edit'
      end
      %W(
        admin/#{resource.class.to_s.underscore.pluralize}/custom_fields_for_#{action}
        admin/#{resource.class.to_s.underscore.pluralize}/custom_fields
      ).map do |partial|
        if lookup_context.exists?(partial, [], true)
          render partial: partial, locals: locals
        end
      end.compact.join.html_safe
    end

    def render_custom_markup_for_index(resource)
      partial = "admin/#{resource.class.to_s.underscore.pluralize}/custom_markup_for_index"
      if lookup_context.exists?(partial, [], true)
        render partial: partial, locals: { resource: resource }
      end
    end

    def field_partial(field, page = field.page)
      @field_partials ||= {}
      @field_partials[field.name] ||= {}
      @field_partials[field.name][page] ||= begin
        # Look up both the resource's class as well as it's base class (when STI is used).
        resource_classes = [field.resource.class, field.resource.class.base_class].uniq
        partial_candidates = resource_classes.map do |klass|
          "admin/#{klass.to_s.underscore.pluralize}/fields/#{field.attribute}/#{page}"
        end + [
          "admin/fields/#{field.attribute}/#{page}",
          "admin/fields/#{field.class.field_type}/#{page}",
          "fields/#{field.class.field_type}/#{page}"
        ]
        partial_candidates.detect do |partial_candidate|
          lookup_context.exists? partial_candidate, [], true
        end
      end
    end

    def cache_key(resource, attributes)
      attribute_keys = attributes.map do |attribute|
        partial = field_partial(attribute)
        partial_digest = ActionView::Digestor.digest(name: partial, finder: lookup_context, partial: true)
        [
          attribute.name,
          attribute.html_class,
          partial,
          partial_digest
        ]
      end
      [resource, *attribute_keys]
    end

    def class_from_resource(resource_name)
      resource_name.to_s.classify.constantize
    end

    def display_resource_name(resource_name, plural = true)
      resource_name = class_from_resource(resource_name).model_name.human
      plural ? resource_name.pluralize : resource_name
    end

    def resource_index_route_key(resource_name)
      ActiveModel::Naming.route_key(class_from_resource(resource_name))
    end

    def sanitized_order_params
      params.permit(:search, :id, :order, :page, :per_page, :direction, :orders)
    end

    def link_to_modal(name = nil, options = nil, html_options = nil, &block)
      html_options, options, name = options, name, capture(&block) if block_given?
      html_options ||= {}
      html_options[:data] ||= {}
      html_options[:data].merge!(toggle: 'modal', target: '#modal', url: url_for(options))
      link_to name, '#', html_options
    end
  end
end
