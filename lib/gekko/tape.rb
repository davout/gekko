module Gekko

  #
  # Records the trading engine messages sequentially
  #
  class Tape

    attr_accessor :events, :logger

    def initialize(logger = nil)
      @events = []
      @logger = logger
    end

    #
    # Prints a message on the tape
    #
    # @param message [Hash] The message to record
    #
    def <<(message)
      message[:sequence] = events.length
      logger && logger.info(message)
      events << message
    end

  end
end
