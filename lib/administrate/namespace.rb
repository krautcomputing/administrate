module Administrate
  class Namespace
    attr_reader :namespace

    def initialize(namespace)
      @namespace = namespace
    end

    def resource_groups
      if resource_groups = Administrate.configuration.resource_groups
        all_resources = resources
        resource_groups.keys.each do |label|
          resource_groups[label].map! do |path|
            Administrate::Resource.new(namespace, path).tap do |resource|
              unless resource.exists?
                fail "Resource #{path} does not exist."
              end
              all_resources.delete(resource)
            end
          end
        end
        resource_groups[nil] = all_resources
        resource_groups
      else
        { nil => resources }
      end
    end

    def resources
      @resources ||= routes.map(&:first).uniq.map do |path|
        Administrate::Resource.new(namespace, path)
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
