require_relative "base"

module Administrate
  module Field
    class Attachment < Base
      def url_parts(namespace)
        if options.key?(:url_parts)
          options[:url_parts].call resource
        else
          [attribute, namespace, resource]
        end
      end
    end
  end
end
