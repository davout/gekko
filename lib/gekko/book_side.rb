module Gekko
  class BookSide < Array

    attr_accessor :side

    # TODO : Fuck side, use a sign

    def initialize(side)
      if [:bid, :ask].include?(side)
        self.side = side
      else
        raise 'Incorrect side provided'
      end
    end

    def insert_order(order)
      idx = find_index do |ord|
        (order.bid? && (ord.price < order.price)) ||
          (order.ask? && (ord.price > order.price))
      end

      insert((idx || -1), order)
    end

    def top
      first && first.price
    end

    def cumulated_depth_at(price)
      dpth = 0
      i    = 0

      while self[i] && ((bid? && (price <= self[i][0])) || (ask? && (price >= self[i][0]))) do
        dpth += self[i][1]
        i += 1
      end

      dpth
    end

    def get_depth_at(price)
      depth = 0
      i     = 0

      while ((length > i) && (depth == 0 || ((buying? && self[i][0] > price) || (selling? && self[i][0] < price)))) do
        if self[i][0] == price
          depth = self[i][1]
        end

        i += 1
      end

      depth
    end

    def set_depth_at(price, depth)
      prev = (self[0] && self[0][0]) || 0

      if get_depth_at(price).zero?
        idx = 0

        unless depth.zero?
          while ((length > idx) && ((buying? && (self[idx][0] > price)) || (selling? && (self[idx][0] < price)))) do
            idx += 1
          end

          insert(idx, [price, depth])
        end
      else
        idx = index do |i|
          i[0] == price
        end
        if depth.zero?
          delete_at(idx)
        else
          self[idx][1] = depth
        end
      end

      do_on_update
    end

    def bid?; buying?; end
    def ask?; !bid?; end

    def buying?
      side == :bid
    end

    def selling?
      !buying?
    end

    def on_update(&block)
      @update_callback = block
      self
    end

    def do_on_update
      @update_callback && @update_callback.call
    end

  end
end
