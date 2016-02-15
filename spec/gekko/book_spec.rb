require_relative '../spec_helper'

describe Gekko::Book do

  before do
    @book = Gekko::Book.new('BTCEUR')
  end

  describe '#bid' do
    it 'should be nil when no order is present' do
      expect(@book.bid).to be_nil
    end

    it 'should return the price of the best bid' do
      @book.receive_order(Gekko::LimitOrder.new(:bid, random_id, random_id, 1_0000_0000, 100_0000))
      @book.receive_order(Gekko::LimitOrder.new(:bid, random_id, random_id, 1_0000_0000, 200_0000))
      expect(@book.bid).to eql(200_0000)
    end
  end

  describe '#execute_trade' do
    it 'should not overflow precision' do
      maker = Gekko::LimitOrder.new(:ask, random_id, random_id, 1_0000_0000, 445_0000_0000)
      taker = Gekko::MarketOrder.new(:bid, random_id, random_id, nil, 5000_0000)

      @book.execute_trade(maker, taker)

      expect taker.filled?
      expect(taker.remaining_quote_margin).to eql(245)
      expect(taker.max_precision)
    end
  end

  describe '#ask' do
    it 'should be nil when no order is present' do
      expect(@book.ask).to be_nil
    end

    it 'should return the price of the best ask' do
      @book.receive_order(Gekko::LimitOrder.new(:ask, random_id, random_id, 1_0000_0000, 100_0000))
      @book.receive_order(Gekko::LimitOrder.new(:ask, random_id, random_id, 1_0000_0000, 200_0000))
      expect(@book.ask).to eql(100_0000)
    end
  end

  context 'with a populated book' do
    before do
      populate_book(@book, {
        bids: [[1_0000_0000, 500_0000], [1_0000_0000, 400_0000], [1_0000_0000, 300_0000], [1_0000_0000, 200_0000]],
        asks: [[1_0000_0000, 600_0000], [1_0000_0000, 700_0000], [1_0000_0000, 800_0000], [1_0000_0000, 900_0000]]
      })
    end

    context 'with an execution to serialize' do
      before do
        @book.receive_order(Gekko::LimitOrder.new(:ask, random_id, random_id, 5000_0000, 200_0000))
      end

      describe '#dump' do
        it 'should dump the state of the book as JSON string' do
          expect(@book.serialize).to be_a(String)
        end
      end

      describe '#load' do
        it 'should load the book and its state from a JSON string' do
          prev_ticker = @book.ticker
          expect(Gekko::Book.deserialize(@book.serialize).ticker).to eql(prev_ticker)
        end

        it 'should accept unsorted orders and sort them before loading them' do
          Timecop.freeze(Time.now + 60) do
            @book.receive_order(Gekko::LimitOrder.new(:bid, random_id, random_id, 42_0000_0000, 300_0000))
            bogus_book = Oj.load(@book.serialize)
            bogus_book['bids'].reverse!
            bogus_book['asks'].reverse!

            reserialized_bogus = Oj.load(Gekko::Book.deserialize(bogus_book.to_json).serialize)
            serialized_normal = Oj.load(@book.serialize)

            %w{ tape received }.each { |i| [reserialized_bogus, serialized_normal].each { |h| h.delete(i) } }

            reserialized_bogus = Oj.dump(reserialized_bogus)
            serialized_normal = Oj.dump(serialized_normal)

            expect(reserialized_bogus).to eql(serialized_normal)
          end
        end
      end
    end

    describe '#receive_order' do
      it 'should remove expired orders as they come during executions' do
        @book.bids[0].expiration = @book.bids[1].expiration = (Time.now.to_i - 1)
        @book.receive_order(Gekko::LimitOrder.new(:ask, random_id, random_id, 2_0000_0000, 200_0000))

        # Expect tape to contain two done messages for expired orders that were still hanging
        # around in the order book
        expect(@book.tape.select { |i| (i[:type] == :done) && (i[:reason] == :expired) }.size).to eql(2)
        expect(@book.ticker[:vwap_24h]).to eql(250_0000)
        expect(@book.ticker[:last]).to eql(200_0000)
        expect(@book.ticker[:volume_24h]).to eql(2_0000_0000)
      end

      it 'should not execute expired orders' do
        expired_order = Gekko::LimitOrder.new(:bid, random_id, random_id, 1_0000_0000, 800_0000, (Time.now.to_i - 1))
        original_tape_size = @book.tape.size
        @book.receive_order(expired_order)
        last_msg = @book.tape.last
        expect(last_msg[:type]).to eql(:reject)
        expect(last_msg[:reason]).to eql(:expired)
        expect(last_msg[:order_id]).to eql(expired_order.id.to_s)
        expect(@book.tape.size - 1).to eql(original_tape_size)
      end

      it 'should detect infinite matching loops' do
        @book.asks[1].id = @book.asks[0].id
        expect { @book.receive_order(Gekko::LimitOrder.new(:bid, random_id, random_id, 2_5000_0000, 800_0000)) }.
          to raise_error('Infinite matching loop detected !!')
      end

      it 'should not allow self-trading' do
        uid = UUID.random_create
        @book.bids[1].uid = uid
        @book.receive_order(Gekko::LimitOrder.new(:ask, random_id, uid, 2_0000_0000, 200_0000))

        expect(@book.tape.select { |i| (i[:type] == :done) && (i[:reason] == :canceled) }.size).to eql(1)
        expect(@book.ticker[:bid]).to eql(200_0000)
        expect(@book.ticker[:ask]).to eql(600_0000)
        expect(@book.ticker[:vwap_24h]).to eql(400_0000)
        expect(@book.ticker[:last]).to eql(300_0000)
        expect(@book.ticker[:volume_24h]).to eql(2_0000_0000)
      end

      it 'should execute a limit bid properly' do
        @book.receive_order(Gekko::LimitOrder.new(:bid, random_id, random_id, 2_5000_0000, 800_0000))
        expect(@book.asks.first.price).to eq(800_0000)
        expect(@book.asks.first.remaining).to eq(5000_0000)
        expect(@book.asks.count).to eq(2)
        expect(@book.spread).to eq(300_0000)
        expect(@book.ask).to eq(800_0000)
        expect(@book.bid).to eq(500_0000)
      end

      it 'should execute a limit ask properly' do
        @book.receive_order(Gekko::LimitOrder.new(:ask, random_id, random_id, 2_5000_0000, 300_0000))
        expect(@book.bids.first.price).to eq(300_0000)
        expect(@book.bids.first.remaining).to eq(5000_0000)
        expect(@book.bids.count).to eq(2)
        expect(@book.spread).to eq(300_0000)
        expect(@book.ask).to eq(600_0000)
        expect(@book.bid).to eq(300_0000)
      end

      it 'should reject duplicate IDs' do
        order = Gekko::LimitOrder.new(:ask, random_id, random_id, 1_0000_0000, 1_0000)
        2.times { @book.receive_order(order) }
        expect(@book.tape.last[:type]).to eql(:reject)
      end

      context 'when placing a market order' do
        it 'should execute an ask properly with limiting size' do
          order = Gekko::MarketOrder.new(:ask, random_id, random_id, 1_0000_0000, nil)
          expect(@book.bid).to eql(500_0000)
          @book.receive_order(order)
          expect(order.done?).to be_truthy
          expect(order.filled?).to be_truthy
          expect(order.remaining).to be_zero
          expect(@book.bid).to eql(400_0000)
          expect(@book.ticker[:last]).to eql(500_0000)
          expect(@book.ticker[:volume_24h]).to eql(1_0000_0000)
          @book.tape.delete_at(@book.tape.length - 1)
          expect(@book.tape.last[:reason]).to eql(:filled)
        end

        it 'should execute an ask properly with limiting quote margin' do
          order = Gekko::MarketOrder.new(:ask, random_id, random_id, 100_0000_0000, 1000_0000)
          expect(@book.bid).to eql(500_0000)
          @book.receive_order(order)
          expect(order.done?).to be_truthy
          expect(order.filled?).to be_truthy
          expect(order.remaining).to eql(97_6666_6666)
          expect(@book.bid).to eql(300_0000)
          expect(@book.bids.first.remaining).to eql(6666_6666)
          expect(@book.ticker[:last]).to eql(300_0000)
          expect(@book.ticker[:volume_24h]).to eql(2_3333_3334)
          @book.tape.delete_at(@book.tape.length - 1)
          expect(@book.tape.last[:reason]).to eql(:filled)
        end

        it 'should execute a bid properly with limiting size and non-limiting quote margin' do
          order = Gekko::MarketOrder.new(:bid, random_id, random_id, 1_0000_0000, 1_000_0000)
          expect(@book.ask).to eql(600_0000)
          @book.receive_order(order)
          expect(order.done?).to be_truthy
          expect(order.filled?).to be_truthy
          expect(order.remaining_quote_margin).to eql(400_0000)
          expect(order.remaining).to be_zero
          expect(@book.ask).to eql(700_0000)
          expect(@book.ticker[:last]).to eql(600_0000)
          expect(@book.ticker[:volume_24h]).to eql(1_0000_0000)
          @book.tape.delete_at(@book.tape.length - 1)
          expect(@book.tape.last[:reason]).to eql(:filled)
        end

        it 'should execute a bid properly with non-limiting size and limiting quote margin' do
          order = Gekko::MarketOrder.new(:bid, random_id, random_id, 1_0000_0000, 400_0000)
          expect(@book.ask).to eql(600_0000)
          @book.receive_order(order)
          expect(order.done?).to be_truthy
          expect(order.filled?).to be_truthy
          expect(order.remaining_quote_margin).to be_zero
          expect(order.remaining).to eql(3333_3334)
          expect(@book.ask).to eql(600_0000)
          expect(@book.ticker[:last]).to eql(600_0000)
          expect(@book.ticker[:volume_24h]).to eql(6666_6666)
          @book.tape.delete_at(@book.tape.length - 1)
          expect(@book.tape.last[:reason]).to eql(:filled)
        end

        it 'should execute a bid properly with limiting quote margin without a size' do
          order = Gekko::MarketOrder.new(:bid, random_id, random_id, nil, 400_0000)
          expect(@book.ask).to eql(600_0000)
          @book.receive_order(order)
          expect(order.done?).to be_truthy
          expect(order.filled?).to be_truthy
          expect(order.remaining_quote_margin).to be_zero
          expect(order.remaining).to be_nil
          expect(@book.ask).to eql(600_0000)
          expect(@book.ticker[:last]).to eql(600_0000)
          expect(@book.ticker[:volume_24h]).to eql(6666_6666)
          @book.tape.delete_at(@book.tape.length - 1)
          expect(@book.tape.last[:reason]).to eql(:filled)
        end

        it 'should execute a larger bid properly with limiting quote margin without a size' do
          order = Gekko::MarketOrder.new(:bid, random_id, random_id, nil, 2700_0000)
          expect(@book.ask).to eql(600_0000)
          @book.receive_order(order)
          expect(order.done?).to be_truthy
          expect(order.filled?).to be_truthy
          expect(order.remaining_quote_margin).to be_zero
          expect(order.remaining).to be_nil
          expect(@book.ask).to eql(900_0000)
          expect(@book.ticker[:last]).to eql(900_0000)
          expect(@book.ticker[:volume_24h]).to eql(3_6666_6666)
          @book.tape.delete_at(@book.tape.length - 1)
          expect(@book.tape.last[:reason]).to eql(:filled)
        end

        context 'when the depth is insufficient' do
          it 'should execute an ask with size properly' do
            order = Gekko::MarketOrder.new(:ask, random_id, random_id, 100_0000_0000, nil)
            expect(@book.bid).to eql(500_0000)
            @book.receive_order(order)
            expect(order.remaining).to eql(96_0000_0000)
            expect(order.remaining_quote_margin).to be_nil
            expect(@book.bid).to be_nil
            expect(@book.ticker[:last]).to eql(200_0000)
            expect(@book.ticker[:volume_24h]).to eql(4_0000_0000)
            @book.tape.delete_at(@book.tape.length - 1)
            expect(@book.tape.last[:reason]).to eql(:killed)
          end

          it 'should execute an ask with quote margin properly' do
            order = Gekko::MarketOrder.new(:ask, random_id, random_id, 100_0000_0000, 100_0000_0000)
            expect(@book.bid).to eql(500_0000)
            @book.receive_order(order)
            expect(order.remaining).to eql(96_0000_0000)
            expect(order.remaining_quote_margin).to eql(99_8600_0000)
            expect(@book.bid).to be_nil
            expect(@book.ticker[:last]).to eql(200_0000)
            expect(@book.ticker[:volume_24h]).to eql(4_0000_0000)
            @book.tape.delete_at(@book.tape.length - 1)
            expect(@book.tape.last[:reason]).to eql(:killed)
          end

          it 'should execute a bid properly' do
            order = Gekko::MarketOrder.new(:bid, random_id, random_id, nil, 100_0000_0000)
            expect(@book.ask).to eql(600_0000)
            @book.receive_order(order)
            expect(order.remaining).to be_nil
            expect(order.remaining_quote_margin).to eql(99_7000_0000)
            expect(@book.ask).to be_nil
            expect(@book.ticker[:last]).to eql(900_0000)
            expect(@book.ticker[:volume_24h]).to eql(4_0000_0000)
            @book.tape.delete_at(@book.tape.length - 1)
            expect(@book.tape.last[:reason]).to eql(:killed)
          end

          it 'should execute a bid with size properly' do
            order = Gekko::MarketOrder.new(:bid, random_id, random_id, 100_0000_0000, 100_0000_0000)
            expect(@book.ask).to eql(600_0000)
            @book.receive_order(order)
            expect(order.remaining).to eql(96_0000_0000)
            expect(order.remaining_quote_margin).to eql(99_7000_0000)
            expect(@book.ask).to be_nil
            expect(@book.ticker[:last]).to eql(900_0000)
            expect(@book.ticker[:volume_24h]).to eql(4_0000_0000)
            @book.tape.delete_at(@book.tape.length - 1)
            expect(@book.tape.last[:reason]).to eql(:killed)
          end

        end
      end

      it 'should not emit a ticker if the bid is not changed' do
        bid = Gekko::LimitOrder.new(:bid, random_id, random_id, 1_0000_0000, 450_0000)
        expect(@book).not_to receive(:tick!)
        @book.receive_order(bid)
      end

      it 'should emit a ticker if the bid is changed' do
        bid  = Gekko::LimitOrder.new(:bid, random_id, random_id, 1_0000_0000, 550_0000)
        expect(@book).to receive(:tick!).once
        @book.receive_order(bid)
      end
    end

    describe '#ticker' do
      it 'should return the ticker' do
        @book.receive_order(Gekko::LimitOrder.new(:ask, random_id, random_id, 2_5000_0000, 300_0000))
        expect(@book.ticker).to eql({
          ask:        600_0000,
          bid:        300_0000,
          last:       300_0000,
          high_24h:   500_0000,
          low_24h:    300_0000,
          spread:     300_0000,
          volume_24h: 2_5000_0000,
          vwap_24h:   420_0000
        })
      end
    end

    describe '#cancel' do
      before do
        @best_bid_oid   = @book.bids[0].id
        @second_bid_oid = @book.bids[1].id
      end

      it 'should knock an order off the book' do
        expect { @book.cancel(@best_bid_oid) }.to change { @book.bids.size }.by(-1)
      end

      it 'should update the ticker if necessary' do
        expect { @book.cancel(@best_bid_oid) }.to change { @book.bid }.from(500_0000).to(400_0000)
      end

      it 'should not update the ticker if not necessary' do
        expect { @book.cancel(@second_bid_oid) }.not_to change { @book.bid }
      end

      it 'should emit a done message with the canceled reason' do
        @book.cancel(@second_bid_oid)
        expect(@book.tape.last).to include({ type: :done, reason: :canceled, order_id: @second_bid_oid.to_s })
      end

      it 'should emit a ticker message if the bid or ask is changed' do
        @book.cancel(@best_bid_oid)
        expect(@book.tape.last).to include({ type: :ticker, bid: 400_0000 })
        expect(@book.tape[@book.tape.length - 2]).to include({ type: :done, reason: :canceled })
      end
    end
  end

  context 'with some expiring orders in the book' do
    before do
      populate_book_in_the_past(@book, {
        bids: [[1_0000_0000, 500_0000, (Time.now.to_i - 10)], [1_0000_0000, 400_0000, (Time.now.to_i - 10)], [1_0000_0000, 300_0000, (Time.now.to_i + 1000)]],
        asks: [[1_0000_0000, 600_0000], [1_0000_0000, 700_0000, (Time.now.to_i - 10)]]
      })
    end

    it 'should remove expired orders from both sides of the book' do
      original_tape_size = @book.tape.size
      expect(@book.bids.size + @book.asks.size).to eql(5)
      @book.remove_expired!
      expect(@book.bids.size + @book.asks.size).to eql(2)
      expect(@book.tape.size - 4).to eql(original_tape_size) # 3 canceled orders and one ticker

      expect(@book.tape.pop[:type]).to eql(:ticker)

      3.times do
        last_evt = @book.tape.pop
        expect(last_evt[:type]).to eql(:done)
        expect(last_evt[:reason]).to eql(:expired)
      end
    end

    it 'should update the ticker as required' do
      expect(@book.ticker[:bid]).to eql(500_0000)
      @book.remove_expired!
      expect(@book.tape.last[:type]).to eql(:ticker)
      expect(@book.ticker[:bid]).to eql(300_0000)
    end
  end

end

