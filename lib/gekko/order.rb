module Gekko
  class Order

    attr_accessor :id, :amount, :price, :expiration

    def initialize(id, amount, price, created_at, expiration = nil)
      @id         = id
      @amount     = amount
      @price      = price
      @expiration = expiration
      @created_at = created_at

      raise 'Price must be a positive integer or be omitted'  if (@price && (!@price.is_a?(Fixnum) || (@price <= 0)))
      raise 'Amount must be a non-zero integer'               if (@amount && (!@amount.is_a?(Fixnum) || @amount.zero?))
      raise 'Orders must have an ID'                          unless @id
      raise 'Expiration must be omitted or be an integer'     unless (@expiration.nil? || (@expiration.is_a?(Fixnum) && @expiration > 0))
      raise 'The order creation timestamp can''t be nil'      if !@created_at
    end

    def to_json
      Oj.dump({
        'id'          => @id,
        'amount'      => @amount,
        'price'       => @price,
        'created_at'  => @created_at,
        'expiration'  => @expiration
      })
    end

    def self.from_json(str)
      o = Oj.load(str)
      new(o['id'], o['amount'], o['price'], o['created_at'], o['expiration']) 
    end

    def self.find(id)
      # Do we need this?
    end

  end
end
