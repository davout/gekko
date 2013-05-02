require 'logger'
require 'em-logger'

module Gekko
  module SynchronousLogger

   @@logging_enabled = true 

    def logger   
      output = Gekko::SynchronousLogger.logging_enabled ? STDOUT : '/dev/null'
      @logger ||= ::Logger.new(output)
    end

    def self.logging_enabled
      @@logging_enabled
    end

    def self.logging_enabled=(v)
      @@logging_enabled = v
    end

  end
end
