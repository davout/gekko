module Gekko

  #
  # Represents a trade order. Trade orders can be either buy (bid) or sell (ask) orders.
  # All orders are identified by an UUID, and must specify a size, and an optional
  # expiration timestamp.
  #
  class Order

    include Serialization

    TRL_STOP_PCT_MULTIPLIER = BigDecimal(1000)

    attr_accessor :id, :uid, :side, :size, :remaining, :price, :expiration, :created_at, :post_only,
      :stop_price, :stop_percent, :stop_offset

    def initialize(side, id, uid, size, opts = {})
      @id           = id
      @uid          = uid
      @side         = side && side.to_sym
      @size         = size
      @remaining    = @size
      @expiration   = opts[:expiration]
      @created_at   = Time.now.to_f
      @post_only    = opts[:post_only]
      @stop_price   = opts[:stop_price]
      @stop_percent = opts[:stop_percent]
      @stop_offset  = opts[:stop_offset]

      raise 'Orders must have an UUID'                        unless @id && @id.is_a?(UUID)
      raise 'Orders must have a user ID'                      unless @uid && @uid.is_a?(UUID)
      raise 'Side must be either :bid or :ask'                unless [:bid, :ask].include?(@side)
      raise 'Size must be a positive integer'                 if (@size && (!@size.is_a?(Fixnum) || @size <= 0))
      raise 'Stop price must be a positive integer'           if (@stop_price && (!@stop_price.is_a?(Fixnum) || @stop_price <= 0))
      raise 'Trailing percentage must be a positive integer'  if (@stop_percent && (!@stop_percent.is_a?(Fixnum) || @stop_percent <= 0 || @stop_percent >= TRL_STOP_PCT_MULTIPLIER))
      raise 'Trailing offset must be a positive integer'      if (@stop_offset && (!@stop_offset.is_a?(Fixnum) || @stop_offset <= 0))
      raise 'Expiration must be omitted or be an integer'     unless (@expiration.nil? || (@expiration.is_a?(Fixnum) && @expiration > 0))
      raise 'The order creation timestamp can''t be nil'      if !@created_at

      if (((@stop_price && 1 )|| 0) + ((@stop_percent && 1 ) || 0) + ((@stop_offset && 1) || 0)) > 1
        raise 'Stop orders must specify exactly one of either stop price, trailing percentage, or trailing offset.'
      end
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
    # Returns +true+ if the order is a STOP order, +false+ otherwise
    #
    # @return [Boolean] Whether this order is a STOP
    #
    def stop?
      !!(stop_price || stop_percent || stop_offset)
    end

    #
    # Returns +true+ if the given price should trigger this order's execution.
    #
    # @param p [Fixnum] The price to which we want to compare the STOP price
    # @return [Boolean] Whether this order should trigger
    #
    def should_trigger?(p)
      p || raise("Provided price can't be nil")
      stop? || raise("Called Order#should_trigger? on a non-stop order")

      (bid? && (stop_price <= p)) || (ask? && (stop_price >= p))
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
