require_relative './spec_helper'

describe Gekko::Book do

  before do
    @book = Gekko::Book.new('BTCEUR')
  end

  describe '#bid' do
    it 'should be nil when no order is present' do
      expect(@book.bid).to be_nil
    end

    it 'should return the price of the best bid' do
      @book.receive_order(Gekko::LimitOrder.new(:bid, random_id, 1_0000_0000, 100_0000))
      @book.receive_order(Gekko::LimitOrder.new(:bid, random_id, 1_0000_0000, 200_0000))
      expect(@book.bid).to eql(200_0000)
    end
  end

  describe '#ask' do
    it 'should be nil when no order is present' do
      expect(@book.ask).to be_nil
    end

    it 'should return the price of the best ask' do
      @book.receive_order(Gekko::LimitOrder.new(:ask, random_id, 1_0000_0000, 100_0000))
      @book.receive_order(Gekko::LimitOrder.new(:ask, random_id, 1_0000_0000, 200_0000))
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

    describe '#receive_order' do
      it 'should execute a limit bid properly' do
        @book.receive_order(Gekko::LimitOrder.new(:bid, random_id, 2_5000_0000, 800_0000))
        expect(@book.asks.first.price).to eq(800_0000)
        expect(@book.asks.first.remaining).to eq(5000_0000)
        expect(@book.asks.count).to eq(2)
        expect(@book.spread).to eq(300_0000)
        expect(@book.ask).to eq(800_0000)
        expect(@book.bid).to eq(500_0000)
      end

      it 'should execute an limit ask properly' do
        @book.receive_order(Gekko::LimitOrder.new(:ask, random_id, 2_5000_0000, 300_0000))
        expect(@book.bids.first.price).to eq(300_0000)
        expect(@book.bids.first.remaining).to eq(5000_0000)
        expect(@book.bids.count).to eq(2)
        expect(@book.spread).to eq(300_0000)
        expect(@book.ask).to eq(600_0000)
        expect(@book.bid).to eq(300_0000)
      end

      it 'should reject duplicate IDs' do
        order = Gekko::LimitOrder.new(:ask, random_id, 1_0000_0000, 1_0000)
        2.times { @book.receive_order(order) }
        expect(@book.tape.last[:type]).to eql(:reject)
      end

      it 'should execute a market bid properly with limiting size' do
        order = Gekko::MarketOrder.new(:bid, random_id, 1_0000_0000, 1_000_0000)
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

      it 'should execute a market ask properly with limiting size' do
        order = Gekko::MarketOrder.new(:ask, random_id, 1_0000_0000, nil)
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

      it 'should execute a market bid properly with limiting quote margin' do
        order = Gekko::MarketOrder.new(:bid, random_id, 1_0000_0000, 400_0000)
        expect(@book.ask).to eql(600_0000)
        @book.receive_order(order)
        expect(order.done?).to be_truthy
        expect(order.filled?).to be_falsey
        expect(order.remaining_quote_margin).to be_zero
        expect(order.remaining).to eql(3333_3334)
        expect(@book.ask).to eql(600_0000)
        expect(@book.ticker[:last]).to eql(600_0000)
        expect(@book.ticker[:volume_24h]).to eql(6666_6666)
        @book.tape.delete_at(@book.tape.length - 1)
        expect(@book.tape.last[:reason]).to eql(:killed)
      end 

    end

    describe '#ticker' do
      it 'should return the ticker' do
        @book.receive_order(Gekko::LimitOrder.new(:ask, random_id, 2_5000_0000, 300_0000))
        #binding.pry
        expect(@book.ticker).to eql({
          ask:        600_0000,
          bid:        300_0000,
          last:       300_0000,
          high_24h:   300_0000,
          low_24h:    300_0000,
          spread:     300_0000,
          volume_24h: 2_5000_0000,
          vwap_24h:   420_0000
        })
      end
    end
  end

end
