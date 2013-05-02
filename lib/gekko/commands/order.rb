require 'oj'

module Gekko
  module Commands
    class Order < ::Gekko::Command

      attr_accessor :order

      def initialize(*args)
        puts args[0].class
        self.order = Gekko::Models::Order.new(args[0]['pair'], args[0]['type'], args[0]['amount'], args[0]['price'])
        super(*args)
      end

      def execute
        @connection.redis.push_tail "#{@pair.downcase}:orders", to_json
        @connection.logger.info("Pushed order into #{@pair.upcase} queue : #{to_json}")
      end

      def to_json
        order.to_json
      end

    end
  end
end

