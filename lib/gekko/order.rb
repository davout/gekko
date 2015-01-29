module Gekko
  class Order

    attr_accessor :id, :amount, :remaining, :price, :expiration, :created_at

    def initialize(id, amount, price, created_at, expiration = nil)
      @id         = id
      @amount     = amount
      @remaining  = @amount
      @price      = price
      @expiration = expiration
      @created_at = created_at

      raise 'Orders must have an UUID'                        unless @id && @id.is_a?(UUID)
      raise 'Price must be a positive integer or be omitted'  if (@price && (!@price.is_a?(Fixnum) || (@price <= 0)))
      raise 'Amount must be a non-zero integer'               if (@amount && (!@amount.is_a?(Fixnum) || @amount.zero?))
      raise 'Expiration must be omitted or be an integer'     unless (@expiration.nil? || (@expiration.is_a?(Fixnum) && @expiration > 0))
      raise 'The order creation timestamp can''t be nil'      if !@created_at
    end

    def self.find(id)
      # Do we need this?
    end

    def fill_or_kill?
      # Market orders are fill or kill
      price.nil?
    end

    def crosses?(other)
      if other && (bid? ^ other.bid?)
        (bid? && (price >= other.price)) || (ask? && (price <= other.price))
      end
    end

    def filled?
      remaining.zero?
    end

    def message(type, h = {})
      {
        type:       type,
        order_id:   id,
        side:       bid? ? :bid : :ask,
        amount:     amount,
        remaining:  remaining,
        price:      price
      }.merge(h)
    end

    def bid?
      amount > 0
    end

    def ask?
      !bid?
    end

  end
end
