require 'oj'

module Gekko
  class Command

    COMMANDS = [:order, :admin, :subscribe]

    def self.build(cmd, connection)
      begin
        parsed = Oj.load(cmd)
        command = class_for_command(parsed['command']).new(parsed, connection)
        command
      rescue
        connection.logger.error("Could not build command from data #{cmd}")
        raise "Couldn't parse command"
      end
    end

    def initialize(data, connection)
      @args = data['args'] 
    end

    def self.class_for_command(command)
      case command
      when 'order' then
        Gekko::Commands::Order
      else
        raise "Invalid command type"
      end
    end
  end
end



