require 'oj'

module Gekko
  module Commands
    class Order < ::Gekko::Command

      attr_accessor :order

      def initialize(data, connection)
        self.order = Gekko::Models::Order.new(data['pair'], data['type'], data['amount'], data['price'], connection.account)
        super(data, connection)
      end

      def execute
        @connection.redis.set(@order.id, @order.to_json).callback do
          @connection.redis.push_tail "#{@order.pair.downcase}:orders", @order.id
        end

        @connection.logger.info("Pushed order into #{@order.pair.upcase} queue : #{@order.to_json}")
      end

    end
  end
end

