module Gekko

  #
  # Represents a trade order. Trade orders can be either buy (bid) or sell (ask) orders.
  # All orders are identified by an UUID, and must specify a size, and an optional
  # expiration timestamp.
  #
  class Order

    include Serialization

    attr_accessor :id, :uid, :side, :size, :remaining, :price, :expiration, :created_at

    def initialize(side, id, uid, size, expiration = nil)
      @id         = id
      @uid        = uid
      @side       = side && side.to_sym
      @size       = size
      @remaining  = @size
      @expiration = expiration
      @created_at = Time.now.to_f

      raise 'Orders must have an UUID'                    unless @id && @id.is_a?(UUID)
      raise 'Orders must have a user ID'                  unless @uid && @uid.is_a?(UUID)
      raise 'Side must be either :bid or :ask'            unless [:bid, :ask].include?(@side)
      raise 'Size must be a positive integer'             if (@size && (!@size.is_a?(Fixnum) || @size <= 0))
      raise 'Expiration must be omitted or be an integer' unless (@expiration.nil? || (@expiration.is_a?(Fixnum) && @expiration > 0))
      raise 'The order creation timestamp can''t be nil'  if !@created_at
    end

    #
    # Returns +true+ if this order can execute against +limit_order+
    #
    # @param limit_order [LimitOrder] The limit order against which we want 
    #   to know if an execution is possible
    #
    def crosses?(limit_order)
      if limit_order
        raise 'Can not test againt a market order' unless limit_order.is_a?(LimitOrder)

        if bid? ^ limit_order.bid?
          is_a?(MarketOrder) || (bid? && (price >= limit_order.price)) || (ask? && (price <= limit_order.price))
        end
      end
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
      hsh = {
        type:       type,
        order_id:   id.to_s,
        side:       side,
        size:       size,
        remaining:  remaining,
        price:      price,
        expiration: expiration
      }.merge(extra_attrs)

      if is_a?(Gekko::MarketOrder)
        hsh.delete(:price)
        hsh[:quote_margin] = quote_margin
        hsh[:remaining_quote_margin] = remaining_quote_margin
      end

      hsh
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

    #
    # Returns +true+ if this order isn't supposed to stick around in
    # the order book
    #
    def fill_or_kill?
      is_a?(Gekko::MarketOrder)
    end

    #
    # Returns +true+ if this order is expired
    #
    def expired?
      expiration && (expiration <= Time.now.to_i)
    end

    #
    # Returns a +Hash+ representation of this +Order+ instance
    #
    # @return [Hash] The serializable representation
    #
    def to_hash
      hsh = {
        id:           id.to_s,
        uid:          uid.to_s,
        side:         side,
        size:         size,
        price:        price,
        remaining:    remaining,
        expiration:   expiration,
        created_at:   created_at
      }

      if is_a?(Gekko::MarketOrder)
        hsh.delete(:price)
        hsh[:quote_margin] = quote_margin
        hsh[:remaining_quote_margin] = remaining_quote_margin
      end

      hsh
    end

    #
    # Initializes a +Gekko::Order+ subclass from a +Hash+ instance
    #
    # @param hsh [Hash] The order data
    # @return [Gekko::Order] A trade order
    #
    def self.from_hash(hsh)
      (hsh[:price] ? LimitOrder : MarketOrder).from_hash(hsh)
    end

  end
end
