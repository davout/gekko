require 'gekko/synchronous_logger'

require 'hiredis'
require 'redis'

module Gekko
  class Matcher

    BRPOP_TIMEOUT = 0.05

    include Gekko::SynchronousLogger

    attr_accessor :pair, :redis, :terminated

    def initialize(pair, redis)
      logger.info("Starting matcher for #{pair} pair with PID #{Process.pid}")
      self.pair  = pair
      self.redis = connect_redis(redis)

      Signal.trap('TERM') do
        self.terminated = true
        logger.warn("Shutting down #{pair} matcher")
      end
    end

    def match!

      self.terminated = false

      queue = "#{@pair.downcase}:orders"

      while !terminated do
        order = Gekko::Models::Order.find(redis.brpop(queue, BRPOP_TIMEOUT))
        logger.info("Popped order from the #{@pair} queue : #{order.to_json}")
        puts 'POP!'
        execute_order(order)
      end

      logger.warn("#{pair} matcher terminated.")

    end

    def connect_redis(redis)
      self.redis = Redis.connect(redis)
    end

    def execute_order(order)

      # Post order to the book
      redis.set(order.id, order.to_json)
      redis.zadd("#{@pair.downcase}:book:#{order.type}", order.price, order.id)
      logger.info("Posted order #{order.to_json} to the #{@pair} book.")

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

