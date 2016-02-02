require 'gekko/book_side'
require 'gekko/tape'
require 'gekko/errors'

module Gekko

  #
  # An order book consisting of a bid side and an ask side
  #
  class Book

    include Serialization

    attr_accessor :pair, :bids, :asks, :tape, :received, :base_precision

    def initialize(pair, opts = {})
      self.pair           = opts[:pair] || pair
      self.bids           = opts[:bids] || BookSide.new(:bid)
      self.asks           = opts[:asks] || BookSide.new(:ask)
      self.tape           = opts[:tape] || Tape.new({ logger: opts[:logger] })
      self.base_precision = opts[:base_precision] || 8
      self.received       = opts[:received] || {}
    end

    #
    # Receives an order and executes it
    #
    # @param order [Order] The order to execute
    #
    def receive_order(order)
      raise 'Order must be a Gekko::LimitOrder or a Gekko::MarketOrder' unless [LimitOrder, MarketOrder].include?(order.class)

      if received.has_key?(order.id.to_s)
        tape << order.message(:reject, reason: :duplicate_id)

      elsif order.expired?
        tape << order.message(:reject, reason: :expired)

      else
        old_ticker = ticker

        self.received[order.id.to_s] = order
        tape << order.message(:received)

        order_side    = order.bid? ? bids : asks
        opposite_side = order.bid? ? asks : bids
        next_match    = opposite_side.first

        while !order.done? && order.crosses?(next_match)
          if next_match.expired?
            tape << opposite_side.shift.message(:done, reason: :expired)
            next_match = opposite_side.first

          else
            trade_price   = next_match.price
            base_size   = [next_match.remaining, order.remaining].min

            if order.is_a?(LimitOrder)
              quote_size = (base_size * trade_price) / (10 ** base_precision)

            elsif order.is_a?(MarketOrder)
              if order.ask? || (order.remaining_quote_margin > ((trade_price * base_size) / (10 ** base_precision)))
                quote_size = ((trade_price * base_size) / (10 ** base_precision))
                order.remaining_quote_margin -= quote_size if order.bid?
              elsif order.bid?
                quote_size = order.remaining_quote_margin
                base_size = (order.remaining_quote_margin * (10 ** base_precision)) / trade_price
                order.remaining_quote_margin -= quote_size
              end
            end

            tape << {
              type:             :execution,
              price:            trade_price,
              base_size:        base_size,
              quote_size:       quote_size,
              maker_order_id:   next_match.id.to_s,
              taker_order_id:   order.id.to_s,
              tick:             order.bid? ? :up : :down
            }

            order.remaining       -= base_size
            next_match.remaining  -= base_size

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

    #
    # Cancels an order given an ID
    #
    # @param order_id [UUID] The ID of the order to cancel
    #
    def cancel(order_id)
      prev_bid = bid
      prev_ask = ask

      order = received[order_id.to_s]
      dels = order.bid? ? bids.delete(order) : asks.delete(order)
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
        bs.reject! do |order| 
          if order.expired?
            tape << order.message(:done, reason: :expired)
            true
          end
        end
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
        vwap_24h:   ((v24h > 0) && (tape.quote_volume_24h * (10 ** base_precision)/ v24h)) || nil
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
        asks: BookSide.new(:ask, orders: hsh[:asks].map { |o| symbolize_keys(o) }),
      })

      book.tape = Tape.from_hash(symbolize_keys(hsh[:tape]))

      book
    end

  end
end

