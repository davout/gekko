module Gekko
  module Models
    class Order

      attr_accessor :id, :account, :pair, :type, :amount, :price

      def self.parse(data)
        parsed = Oj.load(data)
        new(parsed['pair'], parsed['type'], parsed['amount'], parsed['price'])
      end

      def initialize(pair, type, amount, price, account)
        @pair    = pair
        @type    = type
        @amount  = amount
        @price   = price
        @account = account
        @id      = UUID.generate

        raise 'Orders must supply a pair'                                 unless @pair
        raise 'Price must either be a positive BigDecimal or be omitted'  if (@price && (!@price.is_a?(BigDecimal) || (@price <= 0)))
        raise 'Type must be either buy or sell'                           unless ['buy', 'sell'].include?(@type)
        raise 'Amount must either be a positive BigDecimal or be omitted' if (@price && (!@price.is_a?(BigDecimal) || (@price <= 0)))
        raise 'Orders must have an account'                               unless @account
      end

      def to_json
        Oj.dump({
          'account' => @account,
          'pair'    => @pair,
          'amount'  => @amount,
          'price'   => @price,
          'type'    => @type,
          'id'      => @id
        })
      end

      def self.from_json(str)
        o = Oj.load(str)
        new(o['pair'], o['type'], o['amount'], o['price'], o['account'])
      end

      def next_matching(redis)
        n = redis.zrange("#{@pair.downcase}:book:#{type == 'buy' ? 'sell' : 'buy'}", 0, 0)
        n = n.empty? ? nil : Gekko::Models::Order.parse(n[0])
        
        # Return matching order if prices match
        n && (n.type == 'buy' ? (n.price >= price) : (n.price <= price)) && n
      end

      def self.find(order_id, redis)
        from_json(redis.get(order_id))
      end

    def add_to_book(redis) 
      book_price = price.to_f / (10 ** 8)
      book_score = type == 'buy' ? (1.0 / book_price) : book_price
      redis.zadd("#{@pair.downcase}:book:#{type}", book_score, id)
    end

    end
  end
end
