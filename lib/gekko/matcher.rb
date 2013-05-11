require 'gekko/synchronous_logger'

require 'hiredis'
require 'redis'

module Gekko
  class Matcher

    BRPOP_TIMEOUT = 1

    include Gekko::SynchronousLogger

    attr_accessor :pair, :redis, :terminated

    def initialize(pair, redis)
      logger.info("Starting matcher for #{pair} pair with PID #{Process.pid}")
      self.pair = pair
      self.redis = connect_redis(redis)

      Signal.trap('TERM') { self.terminated = true }
      Signal.trap('INT')  { self.terminated = true }
    end

    def match!

      self.terminated = false

      queue = "#{@pair.downcase}:orders"
      logger.info("#{pair} matcher waiting for order on #{queue}")

      while !terminated do
        order_id = redis.brpop(queue, BRPOP_TIMEOUT)

        if order_id
          order = Gekko::Models::Order.find(order_id[1], redis)
          logger.info("Popped order from the #{@pair} queue : #{order.to_json}")
          execute_order(order)
        else
          terminated = true
        end
      end
      logger.warn("#{pair} matcher terminated.")
    end

    def connect_redis(redis)
      self.redis = Redis.connect(redis)
    end

    def execute_order(order)
      executions = []

      while n = order.next_matching(redis)
        trade_price   = n.price
        base_amount   = [n.amount, order.amount].min
        quoted_amount = base_amount / trade_price

        execution = {
          price:            trade_price,
          base_amount:      base_amount,
          quoted_amount:    quoted_amount #,
#          base_account:     order.account,
#          quoted_account:   n.account,
#          base_fee:         (base_amount * Gekko::DEFAULT_FEE).to_i,
#          quoted_fee:       (quoted_amount * Gekko::DEFAULT_FEE).to_i
        }

        executions << execution.keys.inject({}) do |memo, k|
          memo[k] = execution[k]
          memo
        end
      end

      # Post order to the book
      order.add_to_book(redis)
      logger.info("Added order #{order.to_json} to the #{@pair} book.")

      executions
    end

    def self.fork!(pairs, redis)
      @matching_processes = []

      pairs.each do |pair|
        @matching_processes << fork { new(pair, redis).match! }
      end

      @matching_processes
    end

  end
end

