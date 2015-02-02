module Gekko

  #
  # Records the trading engine messages sequentially
  #
  class Tape < Array

    attr_accessor :logger, :last_trade_price

    def initialize(logger = nil)
      @logger           = logger
      @cursor           = 0
      @cursor_24h       = 0
      @volume_24h       = 0
      @quote_volume_24h = 0
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
        # Keep last price up to date
        @last_trade_price = message[:price]

        # Keep 24h volume up to date
        @volume_24h       += message[:base_size]
        @quote_volume_24h += message[:quote_size]
        move_24h_cursor!
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

    #
    # Returns the traded volume for the last 24h
    #
    # @return [Fixnum] The last 24h volume
    #
    def volume_24h
      move_24h_cursor!
      @volume_24h
    end

    #
    # Returns the traded amount of quote currency in the last 24h
    #
    # @return [Fixnum] The last 24h quote currency volume
    #
    def quote_volume_24h
      move_24h_cursor!
      @quote_volume_24h
    end

    #
    # Moves the cursor pointing to the first trade that happened during
    # the last 24h and updates the volume along the way
    #
    def move_24h_cursor!
      time_24h_ago = Time.now.to_f - 24*3600

      while(self[@cursor_24h] && ((self[@cursor_24h][:type] != :execution) || (self[@cursor_24h][:time] < time_24h_ago)))
        if self[@cursor_24h] && self[@cursor_24h][:type] == :execution
          @volume_24h       -= self[@cursor_24h][:base_size]
          @quote_volume_24h -= self[@cursor_24h][:quote_size]
        end

        @cursor_24h += 1
      end
    end
  end
end

