module Administrate
  class Resource
    attr_reader :namespace, :path

    def initialize(namespace, path)
      @namespace = namespace
      @path = path
    end

    def to_s
      name.to_s
    end

    def to_sym
      name
    end

    def name
      path.to_s.gsub(/^#{namespace}\//, "").to_sym
    end

    def exists?
      !!to_s.classify.safe_constantize
    end

    def ==(other)
      namespace.to_s == other.namespace.to_s && path.to_s == other.path.to_s
    end
  end
end
