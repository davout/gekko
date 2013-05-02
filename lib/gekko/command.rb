require 'oj'

module Gekko
  class Command

    COMMANDS = [:order, :admin, :subscribe]

    def self.parse(cmd)
      begin
        parsed = Oj.load(cmd)
        new(parsed)
      rescue
        raise "Couldn't parse command"
      end
    end

    def initialize(data)
      @command = data['command'].to_sym
      @args = data['args'] 
      validate!
    end

    def validate!
      raise "Invalid command" unless valid?
    end

    def valid?
      @command && COMMANDS.include?(@command.to_sym)
    end
  end
end



