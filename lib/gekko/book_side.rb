module Gekko

  #
  # A side of the order book
  #
  class BookSide < Array

    # TODO: Insert orders more smartly by using a dichotomy search

    attr_accessor :side

    def initialize(side)
      raise "Incorrect side <#{side}>" unless [:bid, :ask].include?(side)
      @side = side
    end

    #
    # Inserts an order in the order book so that it remains sort by ascending
    # or descending price, depending on what side of the complete book this is.
    #
    # @param order [Order] The order to insert
    #
    def insert_order(order)
      raise "Can't insert a #{order.side} order on the #{side} side" unless (side == order.side)

      idx = find_index do |ord|
        (bid_side? && (ord.price < order.price)) ||
          (ask_side? && (ord.price > order.price))
      end

      insert((idx || -1), order)
    end

    # 
    # Returns the first order price, or +nil+ if there's no order
    #
    def top
      first && first.price
    end

    #
    # Returns +true if this is the ask side
    #
    def ask_side?
      side == :ask
    end

    #
    # Returns true if this is the bid side
    #
    def bid_side?
      side == :bid
    end

  end
end
