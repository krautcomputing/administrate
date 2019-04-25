require "turbolinks"
require "rails-assets-jquery.floatThead"
require "bootstrap3-datetimepicker-rails"
require "jquery-rails"
require "kaminari"
require "momentjs-rails"
require "neat"
require "bourbon"
require "sass-rails"
require "selectize-rails"
require "sprockets/railtie"

require "administrate/page/form"
require "administrate/page/show"
require "administrate/page/collection"
require "administrate/order"
require "administrate/resource"
require "administrate/resource_resolver"
require "administrate/filter"
require "administrate/namespace"

module Administrate
  class Engine < ::Rails::Engine
    isolate_namespace Administrate

    @@javascripts = []
    @@stylesheets = []

    def self.add_javascript(script)
      @@javascripts << script
    end

    def self.add_stylesheet(stylesheet)
      @@stylesheets << stylesheet
    end

    def self.stylesheets
      @@stylesheets
    end

    def self.javascripts
      @@javascripts
    end

    add_javascript "administrate/application"
    add_stylesheet "administrate/application"
  end
end
