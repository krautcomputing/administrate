require "administrate/engine"
require "administrate/configuration"

module Administrate
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end
  end
end
