module Gekko
  module Models
    class Order

      attr_accessor :id, :pair, :type, :amount, :price

      def self.parse(data)
        parsed = Oj.load(data)
        new(parsed['pair'], parsed['type'], parsed['amount'], parsed['price'])
      end

      def initialize(pair, type, amount, price)
        @pair   = pair
        @type   = type
        @amount = amount
        @price  = price
        @id     = UUID.generate

        raise 'Orders must supply a pair'                               unless @pair
        raise 'Price must either be a positive integer or be omitted'   if (@price && (!@price.is_a?(Fixnum) || (@price <= 0)))
        raise 'Type must be either buy or sell'                         unless ['buy', 'sell'].include?(@type)
        raise 'Amount must either be a positive integer or be omitted'  if (@price && (!@price.is_a?(Fixnum) || (@price <= 0)))
      end

      def to_json
        Oj.dump({
          'pair'   => @pair,
          'amount' => @amount,
          'price'  => @price,
          'type'   => @type,
          'id'     => @id
        })
      end

    end
  end
end
