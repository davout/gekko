module Gekko

  #
  # Records the trading engine messages sequentially
  #
  class Tape < Array

    include Serialization

    # The number of seconds in 24h
    SECONDS_IN_24H = 60 * 60 * 24

    attr_accessor :logger, :last_trade_price
    attr_reader :volume_24h, :high_24h, :low_24h, :open_24h, :var_24h, :cursor

    def initialize(opts = {})
      @logger = opts[:logger]

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
      message.merge!({
        sequence: length,
        time:     Time.now.to_f
      })

      logger && logger.info(message)

      super(message)

      if message[:type] == :execution
        update_ticker(message)
      end
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
    # Recalculates the previous 24h high and low
    #
    def recalc_high_low_24h!
      @high_24h = nil
      @low_24h  = nil

      # Work backwards from current position until the cursor points to an event
      # that's older than 24h
      tmp_cursor  = (length - 1)
      evt         = self[tmp_cursor]

      while (evt && (evt[:time] >= time_24h_ago)) do
        if evt[:type] == :execution
          @high_24h = ((@high_24h.nil? || (evt[:price] > @high_24h)) && evt[:price]) || @high_24h
          @low_24h  = ((@low_24h.nil?  || (evt[:price] < @low_24h))  && evt[:price]) || @low_24h
        end

        tmp_cursor -= 1
        evt = (tmp_cursor >= 0) && self[tmp_cursor]
      end
    end

    #
    # Returns the traded amount of quote currency in the last 24h
    #
    # @return [Fixnum] The last 24h quote currency volume
    #
    def quote_volume_24h
      @quote_volume_24h
    end

    #
    # Updates the ticker after an execution has been recorded
    #
    def update_ticker(execution)
      price = execution[:price]

      # Keep last price up to date
      @last_trade_price = price

      # Keep 24h volume up to date
      @volume_24h       += execution[:base_size]
      @quote_volume_24h += execution[:quote_size]

      # Record new high/lows
      if @high_24h.nil? || (@high_24h < price)
        @high_24h = price
      end

      if @low_24h.nil? || (price < @low_24h)
        @low_24h = price
      end

      move_24h_cursor!
    end

    #
    # Returns the float timestamp of 24h ago
    #
    # @return [Float] Yesterday's cut-off timestamp
    #
    def time_24h_ago
      Time.now.to_f - SECONDS_IN_24H
    end

    #
    # Moves the cursor pointing to the first trade that happened during
    # the last 24h. Every execution getting out of the 24h rolling window is
    # passed to Tape#fall_out_of_24h_window
    #
    def move_24h_cursor!
      while(self[@cursor_24h] && (self[@cursor_24h][:time] < time_24h_ago))
        if self[@cursor_24h][:type] == :execution
          fall_out_of_24h_window(self[@cursor_24h])
        end

        @cursor_24h += 1
      end
    end

    #
    # Updates the low, high, and volumes when an execution falls out of the rolling
    # previous 24h window
    #
    def fall_out_of_24h_window(execution)
      @volume_24h       -= execution[:base_size]
      @quote_volume_24h -= execution[:quote_size]
      @open_24h         = execution[:price]
      @var_24h          = @last_trade_price && ((@last_trade_price - @open_24h) / @open_24h.to_f)

      if [@high_24h, @low_24h].include?(execution[:price])
        recalc_high_low_24h!
      end
    end

    #
    # Returns this +Tape+ object as a +Hash+ for the purpose of serialization
    #
    # @return [Hash] The JSON-friendly +Hash+ representation
    #
    def to_hash
      {
        cursor:             @cursor,
        cursor_24h:         @cursor_24h,
        volume_24h:         @volume_24h,
        high_24h:           @high_24h,
        low_24h:            @low_24h,
        open_24h:           @open_24h,
        var_24h:            @var_24h,
        quote_volume_24h:   @quote_volume_24h,
        last_trade_price:   @last_trade_price,
        events:             self
      }
    end

    #
    # Loads a +Tape+ object from a hash
    #
    # @param hsh [Hash] The +Tape+ data
    #
    def self.from_hash(hsh)
      tape = Tape.new

      tape.instance_variable_set(:@cursor, hsh[:cursor])

      hsh[:events].each do |evt|
        e = symbolize_keys(evt)
        e[:type] = e[:type].to_sym
        tape << e
      end

      tape
    end

  end
end

