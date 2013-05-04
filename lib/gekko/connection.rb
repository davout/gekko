require 'uuid'
require 'oj'

module Gekko
  class Connection < EventMachine::Connection

    attr_accessor :logger, :server, :redis, :connection_id
    attr_reader :account

    @connection_id = nil

    def post_init
      @connection_id = UUID.new.generate
    end

    def log_connection
      port, ip = Socket.unpack_sockaddr_in(get_peername)
      logger.info("Accepted connection from #{ip}:#{port} with ID [#{connection_id}]") 
    end

    def receive_data(data)
      begin
        logger.info("Received data for [#{@connection_id}] : #{data}")
        parsed = Oj.load(data.chomp)
        cmd = Gekko::Command.build(parsed, self)
        cmd.execute
      rescue
        puts $!.message
        logger.error("Received invalid message for connection [#{connection_id}] : \"#{$!.message}\", disconnecting.")
        send_data("Invalid message.\n")
        close_connection_after_writing
      end
    end

    def unbind
      server.connections.delete(self)
    end

    def account=(uuid)
      raise 'Invalid account ID, must be an UUID' unless uuid =~ /\A[\da-f]{8}-([\da-f]{4}-){3}[\da-f]{12}\z/i
      @account = uuid.downcase
    end
  end
end
