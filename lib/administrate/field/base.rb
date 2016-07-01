require_relative "deferred"
require "active_support/core_ext/string/inflections"

module Administrate
  module Field
    class Base
      def self.with_options(options = {})
        Deferred.new(self, options)
      end

      def self.html_class
        field_type.dasherize
      end

      def self.searchable?
        false
      end

      def initialize(attribute, resource, data, page, options = {})
        @attribute = attribute
        @resource = resource
        @data = data
        @page = page
        @options = options
      end

      def self.permitted_attribute(attr)
        attr
      end

      def html_class
        self.class.html_class
      end

      def name
        attribute.to_s
      end

      attr_reader :attribute, :resource, :data, :page

      protected

      attr_reader :options

      def self.field_type
        to_s.split("::").last.underscore
      end
    end
  end
end
