require 'gekko/book_side'

module Gekko
  class Book

    # TODO : Add tick size
    # TODO : Add order size limits
    # TODO : Add order state

    attr_accessor :pair, :bids, :asks

    def initialize(pair)
      self.pair = pair
      self.bids = BookSide.new(:bid)
      self.asks = BookSide.new(:ask)
    end

    # If order is inside spread
    # Place it on top of the relevant side
    # Else if it adds liquidity place it on the relevant side
    # Else if it takes liquidity match it against the other side, and once done, place it on top of its side
    def add_order(order)
      executions = []
      matching_side = order.bid? ? asks : bids
      
      next_order = matching_side.first

      while !order.filled? || order.can_match?(next_order)
        trade_price   = n.price
        base_amount   = [n.amount, order.amount].min
        quoted_amount = base_amount / trade_price

        # Add taker & maker IDs
        execution = {
          price:            trade_price,
          base_amount:      base_amount,
          quoted_amount:    quoted_amount,
          base_fee:         base_amount
        }

        executions << execution
      end

      # Post order to the book

      executions
    end

    def ask
      asks.top
    end

    def bid
      bids.top
    end

    def spread
      ask && bid && (ask - bid)
    end

  end
end

