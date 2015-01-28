require 'gekko/book_side'

module Gekko
  class Book

    # TODO : Add tick size
    # TODO : Add order size limits
    # TODO : Add order state
    # TODO : Add order expiration

    attr_accessor :pair, :bids, :asks

    def initialize(pair)
      self.pair = pair
      self.bids = BookSide.new(:bid)
      self.asks = BookSide.new(:ask)

      @sequence = 1
    end

    def add_order(order)

      results       = []
      order_side    = order.bid? ? bids : asks
      opposite_side = order.bid? ? asks : bids
      next_match    = opposite_side.first

      while !order.filled? && order.crosses?(next_match)
        trade_price   = next_match.price
        base_amount   = [n.amount, order.amount].min

        # TODO : What about the rounding?
        quoted_amount = base_amount / trade_price

        # Add taker & maker IDs
        results << {
          type:             :execution,
          sequence:         incremented_sequence,
          price:            trade_price,
          base_amount:      base_amount,
          quoted_amount:    quoted_amount,
          maker_order_id:   next_match.id,
          taker_order_id:   order.id,
          tick:             order.bid? ? :up : :down
        }

        order.remaining_amount      -= base_amount
        next_match.remaining_amount -= base_amount

        if next_match.remaining_amount.filled?
          opposite_side.shift
          results << next_matching.message(:done, reason: :filled)
        end
      end

      if order.filled?
        results << order.message(:done, reason: :filled)
      elsif order.fill_or_kill?
        results << order.message(:done, reason: :killed)
      else
        order_side.insert_order(order)
        results << order.message(:open)
      end

      results.each { |r| inject_sequence(r) }
      results
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

    def inject_sequence(h)
      h[:sequence] = @sequence
      @sequence += 1
    end

  end
end

