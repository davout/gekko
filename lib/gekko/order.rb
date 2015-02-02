module Gekko

  #
  # Represents a trade order. Trade orders can be either buy (bid) or sell (ask) orders.
  # All orders are identified by an UUID, must specify a size, a price, and an optional
  # expiration timestamp.
  #
  class Order

    attr_accessor :id, :side, :size, :remaining, :price, :expiration, :created_at

    def initialize(side, id, size, price, expiration = nil)

      @id         = id
      @side       = side && side.to_sym
      @size       = size
      @remaining  = @size
      @price      = price
      @expiration = expiration
      @created_at = Time.now.to_f

      raise 'Orders must have an UUID'                        unless @id && @id.is_a?(UUID)
      raise 'Side must be either :bid or :ask'                unless [:bid, :ask].include?(@side)
      raise 'Price must be a positive integer'                if @price.nil? || (!@price.is_a?(Fixnum) || (@price <= 0))
      raise 'Size must be a positive integer'                 if (@size && (!@size.is_a?(Fixnum) || @size <= 0))
      raise 'Expiration must be omitted or be an integer'     unless (@expiration.nil? || (@expiration.is_a?(Fixnum) && @expiration > 0))
      raise 'The order creation timestamp can''t be nil'      if !@created_at
    end

    #
    # Returns +true+ if this order can execute against +other_order+
    #
    # @param other [Order] The other order against which we want 
    #   to know if an execution is possible
    #
    def crosses?(other)
      if other && (bid? ^ other.bid?)
        (bid? && (price >= other.price)) || (ask? && (price <= other.price))
      end
    end

    #
    # Returns +true+ if the order is filled
    #
    def filled?
      remaining.zero?
    end

    #
    # Creates a message in order to print it ont the tape
    #
    # @param type [Symbol] The type of message we're printing
    # @param extra_attrs [Hash] The extra attributes we're including
    #   in the message
    #
    # @return [Hash] The message we'll print on the tape
    #
    def message(type, extra_attrs = {})
      {
        type:       type,
        order_id:   id.to_s,
        side:       side,
        size:       size,
        remaining:  remaining,
        price:      price
      }.merge(extra_attrs)
    end

    #
    # Returns +true+ if this order is a buy order
    #
    def bid?
      side == :bid
    end

    #
    # Returns +true+ if this order is a sell order
    #
    def ask?
      !bid?
    end

  end
end
