require 'eventmachine'
require 'em-hiredis'

require 'gekko/connection'
require 'gekko/default_pairs'
require 'gekko/logger'
require 'gekko/matcher'
require 'gekko/version'

module Gekko
  class Server

    include Gekko::Logger

    def initialize(ip = '0.0.0.0', port = 6943, pairs = Gekko::DEFAULT_PAIRS)

      #      EventMachine.run do

      unless EventMachine.reactor_running?
        raise 'The server must be started inside a running reactor, create it inside a EventMachine.run { } block'
      else
        logger.info("Starting Gekko v#{Gekko::VERSION} with PID #{Process.pid}") 

        Signal.trap('INT')  { shutdown }
        Signal.trap('TERM') { shutdown }

        @matching_processes = []

        pairs.each do |pair|
          @matching_processes << fork { Gekko::Matcher.new(pair) }
        end

        logger.info("Starting network listener on #{ip}:#{port}")

        @network_listener = EventMachine.start_server(ip, port, Gekko::Connection) do |c| 
          c.logger = logger 
          #c.redis  = redis
          c.log_connection
        end
        #      end
      end

    end

    def shutdown
      logger.warn('Shutting down.')
      logger.warn('Terminating network listener')
      EventMachine.stop_server(@network_listener)

      logger.warn('Killing matchers')
      @matching_processes.each { |p| Process.kill('TERM', p) }
      Process.waitall

      EventMachine.stop
    end
  end
end

