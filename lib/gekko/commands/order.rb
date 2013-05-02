require 'oj'

module Gekko
  module Commands
    class Order < ::Gekko::Command

      attr_accessor :order

      def initialize(*args)
        self.order = Gekko::Models::Order.new(args[0]['pair'], args[0]['type'], args[0]['amount'], args[0]['price'])
        super(*args)
      end

      def execute
        @connection.redis.set(@order.id, @order.to_json)
        @connection.redis.push_tail "#{@order.pair.downcase}:orders", @order.id
        @connection.logger.info("Pushed order into #{@order.pair.upcase} queue : #{to_json}")
      end

    end
  end
end

