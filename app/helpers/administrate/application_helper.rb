module Administrate
  module ApplicationHelper
    def page_html_class
      "#{params[:controller].split('/').last} #{params[:action]}"
    end

    def render_field(field, locals = {})
      locals.merge!(field: field)
      # Look up both the resource's class as well as it's base class (when STI is used).
      resource_classes = [field.resource.class, field.resource.class.base_class].uniq
      partial_candidates = resource_classes.map do |klass|
        "admin/#{klass.to_s.underscore.pluralize}/fields/#{field.attribute}/#{field.page}"
      end + [
        "admin/fields/#{field.class.field_type}/#{field.page}",
        "fields/#{field.class.field_type}/#{field.page}"
      ]
      partial = partial_candidates.detect do |partial_candidate|
        lookup_context.exists? partial_candidate, [], true
      end
      unless partial
        fail "Could not find partial for field #{field}."
      end
      render locals: locals, partial: partial
    end

    def display_resource_name(resource_name)
      resource_name.
        to_s.
        classify.
        constantize.
        model_name.
        human(
          count: 0,
          default: resource_name.to_s.pluralize.titleize,
        )
    end

    def svg_tag(asset, svg_id, options = {})
      svg_attributes = {
        "xlink:href".freeze => "#{asset_url(asset)}##{svg_id}",
        height: options[:height],
        width: options[:width],
      }.delete_if { |_key, value| value.nil? }
      xml_attributes = {
        "xmlns".freeze => "http://www.w3.org/2000/svg".freeze,
        "xmlns:xlink".freeze => "http://www.w3.org/1999/xlink".freeze,
      }

      content_tag :svg, xml_attributes do
        content_tag :use, nil, svg_attributes
      end
    end

    def sanitized_order_params
      params.permit(:search, :id, :order, :page, :per_page, :direction)
    end

    def clear_search_params
      params.except(:search, :page).permit(:order, :direction, :per_page)
    end
  end
end
