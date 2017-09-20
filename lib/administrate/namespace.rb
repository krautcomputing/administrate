module Administrate
  class Namespace
    attr_reader :namespace

    def initialize(namespace)
      @namespace = namespace
    end

    def resources
      @resources ||= routes.map(&:first).uniq.map do |path|
        Resource.new(namespace, path)
      end.select(&:exists?)
    end

    def routes
      @routes ||= all_routes.select do |controller, _|
        controller.starts_with?("#{namespace}/")
      end
    end

    private

    def all_routes
      Rails.application.routes.routes.map do |route|
        route.defaults.values_at(:controller, :action).map(&:to_s)
      end
    end
  end
end
