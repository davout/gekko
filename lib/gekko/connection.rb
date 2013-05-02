require 'uuid'
require 'oj'

module Gekko
  class Connection < EventMachine::Connection

    attr_accessor :logger, :server, :redis, :connection_id

    @connection_id = nil

    def post_init
      @connection_id = UUID.new.generate
    end

    def log_connection
      port, ip = Socket.unpack_sockaddr_in(get_peername)
      logger.info("Accepted connection from #{ip}:#{port} with ID [#{connection_id}]") 
    end

    def receive_data(data)
      d = data.chomp

      logger.info("Received data for [#{@connection_id}] : #{d}")

      begin
        cmd = Gekko::Command.build(data, self)
        cmd.execute
      rescue
        logger.error("Received invalid message for connection [#{connection_id}] : \"#{$!.message}\", disconnecting.")
        send_data("Invalid message.\n")
        close_connection_after_writing
      end
    end

    def unbind
      server.connections.delete(self)
    end
  end
end
