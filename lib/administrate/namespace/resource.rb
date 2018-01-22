module Administrate
  class Resource
    attr_reader :namespace, :resource

    def initialize(namespace, resource)
      @namespace = namespace
      @resource = resource
    end

    def to_s
      name.to_s
    end

    def to_sym
      name
    end

    def name
      resource.to_s.gsub(/^#{namespace}\//, "").to_sym
    end

    def path
      name.to_s.gsub("/", "_")
    end

    def exists?
      !!to_s.classify.safe_constantize
    end

    def ==(other)
      namespace.to_s == other.namespace.to_s && resource.to_s == other.resource.to_s
    end
  end
end
