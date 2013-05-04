require 'oj'

module Gekko
  class Command

    def self.build(cmd, connection)
      command = class_for_command(cmd['command']).new(cmd['args'], connection)
      command
    end

    def initialize(data, connection)
      @args       = data
      @connection = connection
    end

    def self.class_for_command(command)
      case command
      when 'order' then
        Gekko::Commands::Order
      when 'authenticate' then
        Gekko::Commands::Authenticate
      else
        raise "Invalid command type"
      end
    end
  end
end



