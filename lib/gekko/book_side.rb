module Gekko
  class BookSide < Array
    
attr_accessor :bid_side

    def initialize(side)
      raise "Incorrect side <#{side}>" unless [:bids, :asks].include?(side)
      @bid_side = (side == :bids)
    end

    def insert_order(order)
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
      !@bid_side
    end

    #
    # Returns true if this is the bid side
    #
    def bid_side?
      @bid_side
    end

  end
end
