module Gekko

  #
  # Represents a limit order. These order must specify a price.
  #
  class LimitOrder < Order

    attr_accessor :price

    def initialize(side, id, size, price, expiration = nil)
      super(side, id, size, expiration)
      @price = price

      raise 'Price must be a positive integer' if @price.nil? || (!@price.is_a?(Fixnum) || (@price <= 0))
    end

    #
    # Returns +true+ if the order is filled
    #
    def filled?
      remaining.zero?
    end

    def done?
      filled?
    end

    #
    # +LimitOrder+s are sorted by ASC price for asks, DESC price for bids,
    # if prices are equal then creation timestamp is used, and older orders
    # get priority.
    #
    # @return [Fixnum] 1 if self < other, -1 if not, 0 if equivalent
    #
    def <=>(other)
      cmp = (ask? ? 1 : -1) * (price <=> other.price)
      cmp = (created_at <=> other.created_at) if cmp.zero?
      cmp
    end

  end
end

