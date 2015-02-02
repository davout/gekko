module Gekko

  #
  # Records the trading engine messages sequentially
  #
  class Tape < Array

    attr_accessor :events, :logger, :last_trade_price

    def initialize(logger = nil)
      @logger = logger
      @cursor = 0
    end

    #
    # Prints a message on the tape
    #
    # @param message [Hash] The message to record
    #
    def <<(message)
      message[:sequence] = length
      logger && logger.info(message)

      if message[:type] == :execution
        @last_trade_price = message[:price]
      end

      super(message)
    end

    #
    # Returns the next unread element from the tape
    #
    # @return [Hash] The next unread element
    #
    def next
      if @cursor < length
        n = self[@cursor]
        @cursor += 1
        n
      end
    end

  end
end

