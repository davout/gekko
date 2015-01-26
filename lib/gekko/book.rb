module Gekko
  class Book

    attr_accessor :base_currency, :quoted_currency

    def initialize(base_currency, quoted_currency)
      self.base_currency    = base_currency
      self.quoted_currency  = quoted_currency

      @sides = {
        bid: BookSide.new,
        ask: BookSide.new
      }
    end

    def receive_order(order)
      executions = []

      while !order.filled?
        trade_price   = n.price
        base_amount   = [n.amount, order.amount].min
        quoted_amount = base_amount / trade_price

        execution = {
          price:            trade_price,
          base_amount:      base_amount,
          quoted_amount:    quoted_amount,
          base_account:     order.account,
          quoted_account:   n.account,
          base_fee:         base_amount
          quoted_fee:       quoted_amount
        }

        executions << execution
      end

      # Post order to the book

      executions
    end

    def ask
      @sides[:ask].top
    end

    def bid
      @sides[:bid].top
    end

    def spread
      ask - bid
    end

  end
end

