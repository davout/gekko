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

    def high_24h
      move_24h_cursor!
      @high_24h
    end

    def recalc_high_24h!
      @high_24h = nil
      # The cursor hasn't yet been incremented
      ((@cursor_24h+1)..(length-1)).each do |idx|
        if (self[idx][:type] == :execution) && (@high_24H.nil? || (self[idx][:price] > @high_24h))
          @high_24h = self[idx][:price]
        end
      end
    end

    def recalc_low_24h!
      @low_24h = nil
      # The cursor hasn't yet been incremented
      ((@cursor_24h+1)..(length-1)).each do |idx|
        if (self[idx][:type] == :execution) && (@low_24h.nil? || (self[idx][:price] < @low_24h))
          @low_24h = self[idx][:price]
        end
      end
    end

    def low_24h
      move_24h_cursor!
      @low_24h
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
        x = self[@cursor_24h]

        if x && x[:type] == :execution
          @volume_24h       -= x[:base_size]
          @quote_volume_24h -= x[:quote_size]

          if x[:price] >= @high_24h
            recalc_high_24h!
          elsif x[:price] <= @low_24h
            recalc_low_24h!
          end
        end

        @cursor_24h += 1
      end
    end
  end
end

