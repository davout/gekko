require 'oj'

module Gekko
  module Commands
    class Order < ::Gekko::Command

      def initialize(*args)
        @pair = args[0]['pair']
        raise 'Orders must supply a pair' unless @pair

        @price = args[0]['price']
        raise 'Price must either be a positive integer or be omitted' if (@price && (!@price.is_a?(Fixnum) || (@price <= 0)))

        @type = args[0]['type']
        raise 'Type must be either buy or sell' unless ['buy', 'sell'].include?(@type)

        @amount = args[0]['amount']
        raise 'Amount must either be a positive integer or be omitted' if (@price && (!@price.is_a?(Fixnum) || (@price <= 0)))

        super(*args)
      end

      def execute
        @connection.redis.push_tail "#{@pair.downcase}:orders", to_json
      @connection.logger.info("Pushed order into #{@pair.upcase} queue : #{to_json}")
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

