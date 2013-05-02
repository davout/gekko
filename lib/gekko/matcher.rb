require 'gekko/synchronous_logger'

require 'hiredis'
require 'redis'

module Gekko
  class Matcher

    include Gekko::SynchronousLogger

    attr_accessor :pair, :redis, :terminated

    def initialize(pair)
      logger.info("Starting matcher for #{pair} pair with PID #{Process.pid}")
      
      self.pair = pair
      
      connect_redis
    end

    def match!
      
      self.terminated = false

      Signal.trap('TERM') do
        self.terminated = true
        logger.warn("Shutting down #{pair} matcher")
      end

      while !terminated do
        order = Gekko::Models::Order.parse(redis.blpop("#{@pair.downcase}:orders"))
        execute_order(order)
      end

      logger.warn("#{pair} matcher terminated.")

    end

    def connect_redis
      self.redis = Redis.connect
    end

    def execute_order(order)

      # Post order to the book
      redis.zadd("#{@pair.downcase}:book:#{order.type}", order.price, order.to_json)
      logger.info("Posted order #{order.to_json} to the #{@pair} book.")

    end
  end
end

