require 'eventmachine'
require 'em-hiredis'

require 'gekko/connection'
require 'gekko/command'
require 'gekko/default_pairs'
require 'gekko/logger'
require 'gekko/matcher'
require 'gekko/version'

module Gekko
  class Server

    include Gekko::Logger

    attr_accessor :pid, :pairs, :ip, :port, :connections, :redis

    def initialize(ip = '0.0.0.0', port = 6943, pairs = Gekko::DEFAULT_PAIRS)
      unless EventMachine.reactor_running?
        raise 'The server must be started inside a running reactor, create it inside a EventMachine.run { } block'
      end

      self.pid         = Process.pid
      self.pairs       = pairs
      self.ip          = ip
      self.port        = port
      self.connections = []

      logger.info("Starting Gekko v#{Gekko::VERSION} with PID #{pid}") 
      logger.info("Starting network listener on #{ip}:#{port}")

      register_signal_handlers
      connect_redis
      fork_matchers
      start_network_listener
      start_informations_tick
    end

    def fork_matchers
      @matching_processes = []
      pairs.each do |pair|
        @matching_processes << fork { Gekko::Matcher.new(pair) }
      end
    end

    def start_network_listener
      @network_listener = EventMachine.start_server(ip, port, Gekko::Connection) do |c| 
        connections << c
        c.server    = self
        c.logger    = logger 
        c.redis     = redis

        c.log_connection
      end
    end

    def register_signal_handlers
      Signal.trap(:INT)  { @shutting_down = true }
      Signal.trap(:TERM) { @shutting_down = true }
      EventMachine.add_periodic_timer(0.5) do
        shutdown if @shutting_down
      end
    end

    def shutdown
      logger.warn('Shutting down.')
      logger.warn('Terminating network listener')
      EventMachine.stop_server(@network_listener)

      logger.warn('Killing matchers...')
      @matching_processes.each { |p| Process.kill('TERM', p) }
      Process.waitall

      EventMachine.stop
    end

    def connect_redis
      EventMachine::Hiredis.logger = logger
      self.redis = EventMachine::Hiredis.connect
    end

    def start_informations_tick
      EventMachine.add_periodic_timer(60) do
        logger.info("#{connections.count} clients currently connected.")
      end
    end
  end
end
