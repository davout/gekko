require 'gekko/book_side'
require 'gekko/tape'
require 'gekko/errors'

module Gekko

  #
  # An order book consisting of a bid side and an ask side
  #
  class Book

    # TODO: Add order size limits
    # TODO: Add order expiration
    # TODO: Test for rounding issues
    # TODO: Check for order ID unicity and add reject messages

    # The default minimum price increment accepted for placed orders
    DEFAULT_TICK_SIZE = 1000

    attr_accessor :pair, :bids, :asks, :tape, :tick_size

    def initialize(pair, opts = {})
      self.pair       = pair
      self.bids       = BookSide.new(:bid)
      self.asks       = BookSide.new(:ask)
      self.tape       = Tape.new(opts[:logger])

      self.tick_size  = opts[:tick_size] || DEFAULT_TICK_SIZE
      raise "Tick size must be a positive integer if provided" if tick_size && (!tick_size.is_a?(Fixnum) || tick_size <= 0)
    end

    #
    # Receives an order and executes it 
    #
    # @param order [Order] The order to execute
    #
    def receive_order(order)

      raise Gekko::TickSizeMismatch unless (order.price % tick_size).zero?

      tape << order.message(:received)

      order_side    = order.bid? ? bids : asks
      opposite_side = order.bid? ? asks : bids
      next_match    = opposite_side.first

      while !order.filled? && order.crosses?(next_match)

        trade_price   = next_match.price
        base_size   = [next_match.remaining, order.remaining].min

        quoted_size = base_size / trade_price

        tape << {
          type:             :execution,
          price:            trade_price,
          base_size:        base_size,
          quoted_size:      quoted_size,
          maker_order_id:   next_match.id.to_s,
          taker_order_id:   order.id.to_s,
          time:             Time.now.to_f,
          tick:             order.bid? ? :up : :down
        }

        executions_24h << [base, trade_price, Time.now.to_f]

        order.remaining       -= base_size
        next_match.remaining  -= base_size

        if next_match.filled?
          tape << opposite_side.shift.message(:done, reason: :filled)
          next_match = opposite_side.first
        end
      end

      if order.filled?
        tape << order.message(:done, reason: :filled)
      else
        order_side.insert_order(order)
        tape << order.message(:open)
      end

      tick!
    end

    #
    # Returns the current best ask price or +nil+ if there
    # are currently no asks
    #
    def ask
      asks.top
    end

    #
    # Returns the current best bid price or +nil+ if there
    # are currently no bids
    #
    def bid
      bids.top
    end

    #
    # Returns the current spread if at least a bid and an ask
    # are present, returns +nil+ otherwise
    #
    def spread
      ask && bid && (ask - bid)
    end

    def tick!
      tape << {
        type:   :ticker,
        bid:    bid,
        ask:    ask,
        spread: spread,
        last:   last,
        high:   high,
        low:    low,
        volume: volume,
        vwap:   vwap,
        time:   Time.now.to_f
      }
    end

    def to_s
      "Bids: <#{bids.map { |o| "#{o.remaining}@#{o.price}" }. join(', ')}> -- Asks: <#{asks.map { |o| "#{o.remaining}@#{o.price}" }. join(', ')}>"
    end

  end
end

