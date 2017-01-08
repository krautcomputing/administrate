module Administrate
  class FiltersController < ActionController::Base
    def create
      referer = parse_referer

      if params[:filter][:value].blank?
        delete_filter_from_query_values referer, params[:filter][:key]
      else
        resource_resolver = Administrate::ResourceResolver.new("admin#{referer.path}")
        filter = Filter::Finder.new(resource_resolver, params[:filter][:key]).find_and_assign_value(params[:filter][:value])

        filter_query_key = "filters[#{filter.key}]"
        if filter.kind == :select_multiple
          filter_query_key << '[]'
        end

        filter_query_values = Array(filter.value).map do |filter_value|
          [filter_query_key, filter_value.key]
        end
        referer.query_values = Array(referer.query_values(Array)).reject { |query_value| query_value.first == filter_query_key }
                                                                 .concat(filter_query_values)
      end

      redirect_to referer.to_s
    end

    def destroy
      referer = parse_referer
      delete_filter_from_query_values referer, params[:id]
      redirect_to referer.to_s
    end

    private

    def delete_filter_from_query_values(referer, key)
      referer.query_values = Array(referer.query_values(Array)).reject do |query_value|
        /\Afilters\[#{Regexp.escape(key)}\]/.match?(query_value.first)
      end.presence
    end

    def parse_referer
      Addressable::URI.parse(request.referer)
    end
  end
end
