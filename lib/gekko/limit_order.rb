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

  end
end

