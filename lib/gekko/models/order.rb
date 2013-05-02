module Gekko
  module Models
    class Order

      attr_accessor :type, :amount, :price

      def self.parse(data)
        puts "Parsing #{data}"
        parsed = Oj.load(data)
        new(parsed['type'], parsed['amount'], parsed['price'])
      end

      def initialize(type, amount, price)
        @type   = type
        @amount = amount
        @price  = price
      end

      def to_json
        Oj.dump({
          'amount' => @amount,
          'price'  => @price,
          'type'   => @type
        })
      end

    end
  end
end
