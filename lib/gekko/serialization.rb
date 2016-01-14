require 'gekko/symbolize_keys'

module Gekko

  #
  # Handles JSON serialization and deserialization of trade orders
  #
  module Serialization

    #
    # Make our class methods available directly on +Gekko::Order+
    #
    def self.included(base)
      base.extend(ClassMethods)
    end

    #
    # De-serialization methods to be made available directly on +Gekko::Order+
    #
    module ClassMethods

      include SymbolizeKeys

      #
      # Deserializes a +Gekko::Order+ subclass from JSON
      #
      # @param serialized [String] The JSON string
      # @return [Gekko::Order] The deserialized trade order
      #
      def deserialize(serialized)
        from_hash(symbolize_keys(Oj.load(serialized)))
      end

      #
      # Initializes a +Gekko::Order+ subclass from a +Hash+ instance
      #
      # @param hsh [Hash] The order data
      # @return [Gekko::Order] A trade order
      #
      def from_hash(hsh)
        order = if hsh[:price]
                  LimitOrder.new(hsh[:side], UUID.parse(hsh[:id]), hsh[:size], hsh[:price], hsh[:expiration])
                else
                  MarketOrder.new(hsh[:side], UUID.parse(hsh[:id]), hsh[:size], hsh[:quote_margin])
                end

        order.created_at = hsh[:created_at] if hsh[:created_at]
        order
      end
    end

    #
    # Serializes a +Gekko::Order+ as JSON
    #
    # @param order [Gekko::Order] The order to serialize
    # @return [String] The JSON string
    #
    def serialize
      Oj.dump(to_hash)
    end

    #
    # Returns a +Hash+ representation of this +Order+ instance
    #
    # @return [Hash] The serializable representation
    #
    def to_hash
      hsh = {
        id:           id.to_s,
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

  end
end

