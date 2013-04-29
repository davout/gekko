require 'gekko/logger'

module Gekko
  class Matcher

    include Gekko::Logger

    attr_accessor :pair

    def initialize(pair)
      logger.info("Starting matcher for #{pair} pair with PID #{Process.pid}")
      @pair = pair
      match
    end

    def match
      terminated = false

      Signal.trap('TERM') do
        terminated = true
        logger.warn("Shutting down #{pair} matcher")
        puts("ouch")
      end

      while !terminated do
        sleep(1)
      end

      logger.warn("#{pair} matcher terminated.")
      puts "argh"
    end
  end
end

