require 'gekko/book_side'
require 'gekko/tape'
require 'gekko/errors'

module Gekko

  #
  # An order book consisting of a bid side and an ask side
  #
  class Book

    extend Forwardable
    include Serialization

    attr_accessor :pair, :bids, :asks, :tape, :received, :base_precision, :multiplier

    def_delegators :@tape, :logger, :logger=

    def initialize(pair, opts = {})
      self.pair           = opts[:pair] || pair
      self.bids           = opts[:bids] || BookSide.new(:bid)
      self.asks           = opts[:asks] || BookSide.new(:ask)
      self.tape           = opts[:tape] || Tape.new({ logger: opts[:logger] })
      self.base_precision = opts[:base_precision] || 8
      self.multiplier     = BigDecimal(10 ** base_precision)
      self.received       = opts[:received] || {}
    end

    #
    # Receives an order and executes it
    #
    # @param order [Order] The order to execute
    #
    def receive_order(order)
      raise "Order must be a Gekko::LimitOrder or a Gekko::MarketOrder."      unless [LimitOrder, MarketOrder].include?(order.class)
      raise "Can't receive a new STOP before a first trade has taken place."  if order.stop? && ticker[:last].nil?

      # We need to initialize the stop_price for trailing stops if necessary
      if order.stop? && !order.stop_price
        if order.stop_price
          order.stop_price = ticker[:last] + order.stop_percent / Gekko::Order::TRL_STOP_PCT_MULTIPLIER * (order.bid? ? 1 : -1)
        elsif order.stop_offset
          order.stop_price = ticker[:last] + order.stop_offset * (order.bid? ? 1 : -1)
        end
      end

      # The side from which we'll pop orders
      opposite_side = order.bid? ? asks : bids

      if received.has_key?(order.id.to_s)
        tape << order.message(:reject, reason: :duplicate_id)

      else
        self.received[order.id.to_s] = order

        if order.expired?
          tape << order.message(:reject, reason: :expired)

        elsif order.stop? && !order.should_trigger?(ticker[:last])
          (order.ask? ? asks : bids).stops << order # Add the STOP to the list of currently active STOPs

        elsif order.post_only && order.crosses?(opposite_side.first)
          tape << order.message(:reject, reason: :would_execute)

        else
          old_ticker = ticker
          tape << order.message(:received)

          order_side    = order.bid? ? bids : asks
          next_match    = opposite_side.first
          prev_match_id = nil

          while !order.done? && order.crosses?(next_match)
            # If we match against the same order twice in a row, something went seriously
            # wrong, we'd rather noisily die at this point.
            raise 'Infinite matching loop detected !!' if (prev_match_id == next_match.id)
            prev_match_id = next_match.id

            if next_match.expired?
              tape << opposite_side.shift.message(:done, reason: :expired)
              next_match = opposite_side.first

            elsif order.uid == next_match.uid
              # Same user/account associated to order, we cancel the next match
              tape << opposite_side.shift.message(:done, reason: :canceled)
              next_match = opposite_side.first

            else
              execute_trade(next_match, order)

              if next_match.filled?
                tape << opposite_side.shift.message(:done, reason: :filled)
                next_match = opposite_side.first
              end
            end
          end

          if order.filled?
            tape << order.message(:done, reason: :filled)
          elsif order.fill_or_kill?
            tape << order.message(:done, reason: :killed)
          else
            order_side.insert_order(order)
            tape << order.message(:open)
          end

          tick! unless (ticker == old_ticker)
        end
      end
    end

    #
    # Executes a trade between two orders
    #
    # @param maker [Gekko::LimitOrder] The order in the book providing liquidity
    # @param taker [Gekko::Order] The order being executed
    #
    def execute_trade(maker, taker)
      trade_price     = maker.price
      max_quote_size  = nil

      # Rounding direction depends on the takers direction
      rounding = (taker.bid? ? :floor : :ceil)

      if taker.is_a?(MarketOrder)
        max_size_with_quote_margin = taker.remaining_quote_margin &&
          (taker.remaining_quote_margin * multiplier / trade_price).send(rounding)
      end

      base_size = [
        maker.remaining,
        taker.remaining,
        max_size_with_quote_margin
      ].compact.min

      if taker.is_a?(LimitOrder)
        quote_size = (base_size * trade_price) / multiplier

      elsif taker.is_a?(MarketOrder)
        if base_size == max_size_with_quote_margin
          taker.max_precision = true
        end

        quote_size = [(trade_price * base_size / multiplier).round, taker.remaining_quote_margin].compact.min
        taker.remaining_quote_margin -= quote_size if taker.quote_margin
      end

      tape << {
        type:       :execution,
        price:      trade_price,
        base_size:  base_size,
        quote_size: quote_size,
        maker_id:   maker.id.to_s,
        taker_id:   taker.id.to_s,
        tick:       taker.bid? ? :up : :down
      }

      taker.remaining  -= base_size if taker.remaining
      maker.remaining  -= base_size
    end

    #
    # Cancels an order given an ID
    #
    # @param order_id [UUID] The ID of the order to cancel
    #
    def cancel(order_id)
      prev_bid = bid
      prev_ask = ask

      order = received[order_id.to_s]
      s = order.bid? ? bids : asks
      dels = s.delete(order) || s.stops.delete(order)
      dels && tape << order.message(:done, reason: :canceled)

      tick! if (prev_bid != bid) || (prev_ask != ask)
    end

    #
    # Removes all expired orders from the book
    #
    def remove_expired!
      prev_bid = bid
      prev_ask = ask

      [bids, asks].each do |bs|
        bs.remove_expired! { |tape_msg| tape << tape_msg }
      end

      tick! if (prev_bid != bid) || (prev_ask != ask)
    end

    #
    # Returns the current best ask price or +nil+ if there
    # are currently no asks
    #
    def ask
      asks.top
    end

    #
    # Returns the current best bid price or +nil+ if there
    # are currently no bids
    #
    def bid
      bids.top
    end

    #
    # Returns the current spread if at least a bid and an ask
    # are present, returns +nil+ otherwise
    #
    def spread
      ask && bid && (ask - bid)
    end

    #
    # Emits a ticker on the tape
    #
    def tick!
      tape << { type: :ticker }.merge(ticker)
    end

    #
    # Returns the current ticker
    #
    # @return [Hash] The current ticker
    #
    def ticker
      v24h = tape.volume_24h
      {
        last:       tape.last_trade_price,
        bid:        bid,
        ask:        ask,
        high_24h:   tape.high_24h,
        low_24h:    tape.low_24h,
        spread:     spread,
        volume_24h: v24h,

        # We'd like to return +nil+, not +false+ when we don't have any volume
        vwap_24h:   ((v24h > 0) && (tape.quote_volume_24h * multiplier / v24h).to_i) || nil
      }
    end

    #
    # Returns a +Hash+ representation of this +Book+ instance
    #
    # @return [Hash] The serializable representation
    #
    def to_hash
      {
        time:             Time.now.to_f,
        bids:             bids.to_hash,
        asks:             asks.to_hash,
        pair:             pair,
        tape:             tape.to_hash,
        received:         received,
        base_precision:   base_precision
      }
    end

    #
    # Loads the book from a hash
    #
    # @param hsh [Hash] A Book hash
    # @return [Gekko::Book] The loaded book instance
    #
    def self.from_hash(hsh)
      book = Book.new(hsh[:pair], {
        bids: BookSide.new(:bid, orders: hsh[:bids].map { |o| symbolize_keys(o) }),
        asks: BookSide.new(:ask, orders: hsh[:asks].map { |o| symbolize_keys(o) })
      })

      [:bids, :asks].each { |s| book.send(s).each { |ord| book.received[ord.id.to_s] = ord } }
      book.tape = Tape.from_hash(symbolize_keys(hsh[:tape])) if hsh[:tape]

      book
    end

  end
end

