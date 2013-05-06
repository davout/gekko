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
        end
      end

      logger.warn("#{pair} matcher terminated.")
    end

    def connect_redis(redis)
      self.redis = Redis.connect(redis)
    end

    def execute_order(order)
      redis.set(order.id, order.to_json)

      executions = []

      while n = order.next_matching
        trade_price = n.price
        base_amount = [n.amount, amount].min

        executions << {
          price:       trade_price,
          base_amount: base_amount,
          quoted_amount: base_amount / trade_price # boo
        }
      end


      # Post order to the book
      add_to_book(order)
    end

    def add_to_book(order)  
      book_score = order.type == 'buy' ? (1.0 / order.price) : order.price
      redis.zadd("#{@pair.downcase}:book:#{order.type}", book_score, order.id)
      logger.info("Added order #{order.to_json} to the #{@pair} book.")
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

