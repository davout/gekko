require 'gekko/book_side'
require 'gekko/tape'

module Gekko
  class Book

    # TODO : Add tick size
    # TODO : Add order size limits
    # TODO : Add order state
    # TODO : Add order expiration

    attr_accessor :pair, :bids, :asks, :tape

    def initialize(pair, opts = {})
      self.pair = pair
      self.bids = BookSide.new(:bids)
      self.asks = BookSide.new(:asks)
      self.tape = Tape.new(opts[:logger])
    end

    #
    # Receives an order and executes it 
    #
    # @param order [Order] The order to execute
    #
    def receive_order(order)

      order_side    = order.bid? ? bids : asks
      opposite_side = order.bid? ? asks : bids
      next_match    = opposite_side.first

      while !order.filled? && order.crosses?(next_match)
        trade_price   = next_match.price
        base_amount   = [n.amount, order.amount].min

        # TODO : What about the rounding?
        quoted_amount = base_amount / trade_price

        tape << {
          type:             :execution,
          price:            trade_price,
          base_amount:      base_amount,
          quoted_amount:    quoted_amount,
          maker_order_id:   next_match.id,
          taker_order_id:   order.id,
          time:             Time.now.to_f,
          tick:             order.bid? ? :up : :down
        }

        order.remaining_amount      -= base_amount
        next_match.remaining_amount -= base_amount

        if next_match.remaining_amount.filled?
          tape << opposite_side.shift.message(:done, reason: :filled)
        end
      end

      if order.filled?
        tape << order.message(:done, reason: :filled)
      elsif order.fill_or_kill?
        tape << order.message(:done, reason: :killed)
      else
        order_side.insert_order(order)
        tape << order.message(:open)
      end
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

  end
end

