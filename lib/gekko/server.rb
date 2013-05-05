require 'eventmachine'
require 'em-hiredis'

require 'gekko/connection'
require 'gekko/command'
require 'gekko/logger'
require 'gekko/matcher'
require 'gekko/version'

module Gekko
  class Server

    include Gekko::Logger

    attr_accessor :pid, :pairs, :ip, :port, :connections, :redis, :network_listener

    def initialize(ip, port, pairs, redis)
      unless EventMachine.reactor_running?
        raise 'The server must be started inside a running reactor, create it inside a EventMachine.run { } block'
      end

      self.pid         = Process.pid
      self.pairs       = pairs
      self.ip          = ip
      self.port        = port
      self.connections = []
      self.redis       = connect_redis(redis)

      logger.info("Starting Gekko v#{Gekko::VERSION} with PID #{pid}") 
      logger.info("Starting network listener on #{ip}:#{port}")

      start_network_listener
      start_informations_tick
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

    def connect_redis(redis)
      EventMachine::Hiredis.logger = logger
      conn_string = "redis://#{redis[:host]}:#{redis[:port]}/#{redis[:database]}"
      self.redis = EventMachine::Hiredis.connect(conn_string)
    end

    def start_informations_tick
      EventMachine.add_periodic_timer(60) do
        logger.info("#{connections.count} clients currently connected.")
      end
    end
  end
end
