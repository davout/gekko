require 'gekko/server'
require 'gekko/command'
require 'gekko/commands/authenticate'
require 'gekko/commands/order'
require 'gekko/commands/ticker'
require 'gekko/models/order'
require 'gekko/models/ticker'

module Gekko

  # Default pairs for which a matching process should be spawned
  DEFAULT_PAIRS = [ 'BTCLTC', 'BTCXRP' ]

  # Default Redis DB to connect to
  DEFAULT_REDIS = { host: '0.0.0.0', db: 15, port: 6379 }

  extend Gekko::Logger

  # Forks matching processes and a networtk listener
  def self.start!(ip = '0.0.0.0', port = 6943, pairs = DEFAULT_PAIRS, redis = DEFAULT_REDIS)
    @matchers = Gekko::Matcher.fork!(pairs, redis) 

    EventMachine.run do
      register_signal_handlers
      @network_listener = Gekko::Server.new(ip, port, @matchers, redis).network_listener
      yield if block_given?
    end
  end

  def self.shutdown
    logger.warn('Shutting down.')

    logger.warn('Terminating network listener')
    EventMachine.stop_server(@network_listener)

    logger.warn('Killing matchers...')
    @matchers.each { |p| Process.kill('TERM', p) }
    Process.waitall

    EventMachine.stop
  end

  def self.register_signal_handlers
    Signal.trap(:INT)  { @shutting_down = true }
    Signal.trap(:TERM) { @shutting_down = true }

    EventMachine.add_periodic_timer(0.05) do
      shutdown if @shutting_down
    end
  end

end
