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
      @book.receive_order(Gekko::Order.new(:bid, random_id, 1_0000_0000, 100_0000))
      @book.receive_order(Gekko::Order.new(:bid, random_id, 1_0000_0000, 200_0000))
      expect(@book.bid).to eql(200_0000)
    end
  end

  describe '#ask' do
    it 'should be nil when no order is present' do
      expect(@book.ask).to be_nil
    end

    it 'should return the price of the best ask' do
      @book.receive_order(Gekko::Order.new(:ask, random_id, 1_0000_0000, 100_0000))
      @book.receive_order(Gekko::Order.new(:ask, random_id, 1_0000_0000, 200_0000))
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
      it 'should execute a bid properly' do
        @book.receive_order(Gekko::Order.new(:bid, random_id, 2_5000_0000, 800_0000))
        expect(@book.asks.first.price).to eq(800_0000)
        expect(@book.asks.first.remaining).to eq(5000_0000)
        expect(@book.asks.count).to eq(2)
        expect(@book.spread).to eq(300_0000)
        expect(@book.ask).to eq(800_0000)
        expect(@book.bid).to eq(500_0000)
      end

      it 'should execute an ask properly' do
        @book.receive_order(Gekko::Order.new(:ask, random_id, 2_5000_0000, 300_0000))
        expect(@book.bids.first.price).to eq(300_0000)
        expect(@book.bids.first.remaining).to eq(5000_0000)
        expect(@book.bids.count).to eq(2)
        expect(@book.spread).to eq(300_0000)
        expect(@book.ask).to eq(600_0000)
        expect(@book.bid).to eq(300_0000)
      end

      it 'should reject duplicate IDs' do
        order = Gekko::Order.new(:ask, random_id, 1000, @book.tick_size)
        2.times { @book.receive_order(order) }
        expect(@book.tape.last[:type]).to eql(:reject)
      end
    end

    describe '#ticker' do
      it 'should return the ticker' do
        @book.receive_order(Gekko::Order.new(:ask, random_id, 2_5000_0000, 300_0000))
        expect(@book.ticker).to eql({
          ask:        600_0000,
          bid:        300_0000,
          last:       300_0000,
          spread:     300_0000,
          volume_24h: 2_5000_0000,
          vwap_24h:   420_0000
        })
      end
    end
  end

end
