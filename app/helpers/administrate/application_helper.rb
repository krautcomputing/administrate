module Administrate
  module ApplicationHelper
    PLURAL_MANY_COUNT = 2.1

    def page_html_class
      "#{params[:controller].split('/').last} #{params[:action]}"
    end

    def render_field(field, locals = {})
      render partial: field_partial(field), locals: locals.merge(field: field)
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

    def field_partial(field)
      @field_partials ||= {}
      @field_partials[field.name] ||= begin
        # Look up both the resource's class as well as it's base class (when STI is used).
        resource_classes = [field.resource.class, field.resource.class.base_class].uniq
        partial_candidates = resource_classes.map do |klass|
          "admin/#{klass.to_s.underscore.pluralize}/fields/#{field.attribute}/#{field.page}"
        end + [
          "admin/fields/#{field.attribute}/#{field.page}",
          "admin/fields/#{field.class.field_type}/#{field.page}",
          "fields/#{field.class.field_type}/#{field.page}"
        ]
        partial = partial_candidates.detect do |partial_candidate|
          lookup_context.exists? partial_candidate, [], true
        end
        unless partial
          fail "Could not find partial for field #{field}."
        end
        partial
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

    def display_resource_name(resource_name)
      resource_name.
        to_s.
        classify.
        constantize.
        model_name.
        human(
          count: PLURAL_MANY_COUNT,
          default: resource_name.to_s.pluralize.titleize,
        )
    end

    def svg_tag(asset, svg_id, options = {})
      svg_attributes = {
        "xlink:href".freeze => "#{asset_url(asset)}##{svg_id}",
        height: "100%",
        width: "100%",
      }
      xml_attributes = {
        "xmlns".freeze => "http://www.w3.org/2000/svg".freeze,
        "xmlns:xlink".freeze => "http://www.w3.org/1999/xlink".freeze,
        height: options[:height],
        width: options[:width],
      }.delete_if { |_key, value| value.nil? }

      content_tag :svg, xml_attributes do
        content_tag :use, nil, svg_attributes
      end
    end

    def sanitized_order_params
      params.permit(:search, :id, :order, :page, :per_page, :direction)
    end
  end
end
