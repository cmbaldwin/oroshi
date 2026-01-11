# frozen_string_literal: true

module Oroshi
  class Configuration
    attr_accessor :time_zone, :locale, :domain

    def initialize
      @time_zone = "Asia/Tokyo"
      @locale = :ja
      @domain = "localhost"
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
