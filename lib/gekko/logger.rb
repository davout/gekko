require 'logger'
require 'em-logger'

module Gekko
  module Logger
    def logger   
      @logger ||= EventMachine::Logger.new(::Logger.new(STDOUT))
    end
  end
end
