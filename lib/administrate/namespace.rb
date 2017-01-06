module Administrate
  class Namespace
    def initialize(namespace)
      @namespace = namespace
    end

    def resources
      namespace_controller_paths.uniq.map do |controller|
        controller.sub(/^#{namespace}\//, "").to_sym
      end.select do |resource|
        resource.to_s.classify.safe_constantize
      end
    end

    def namespace_controller_paths
      all_controller_paths.select do |controller|
        controller.starts_with?("#{namespace}/")
      end
    end

    private

    attr_reader :namespace

    def all_controller_paths
      Rails.application.routes.routes.map do |route|
        route.defaults[:controller].to_s
      end
    end
  end
end
