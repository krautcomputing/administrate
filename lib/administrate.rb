require "administrate/engine"
require "administrate/configuration"

module Administrate
  NOTICE_RESPONSE_HEADER = 'X-Uplink-Notice'

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end
  end
end
