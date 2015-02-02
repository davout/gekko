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
      @book.receive_order(Gekko::Order.new(:bid, random_id, 1, 1000))
      @book.receive_order(Gekko::Order.new(:bid, random_id, 1, 2000))
      expect(@book.bid).to eql(2000)
    end
  end

  describe '#ask' do
    it 'should be nil when no order is present' do
      expect(@book.ask).to be_nil
    end

    it 'should return the price of the best ask' do
      @book.receive_order(Gekko::Order.new(:ask, random_id, 1, 1000))
      @book.receive_order(Gekko::Order.new(:ask, random_id, 1, 2000))
      expect(@book.ask).to eql(1000)
    end
  end

  describe '#receive_order' do
    before do
      populate_book(@book, {
        bids: [[1000, 50000], [1000, 40000], [1000, 30000], [1000, 20000]],
        asks: [[1000, 60000], [1000, 70000], [1000, 80000], [1000, 90000]]
      })
    end

    it 'should execute a bid properly' do
      @book.receive_order(Gekko::Order.new(:bid, random_id, 2500, 80000))
      expect(@book.asks.first.price).to eq(80000)
      expect(@book.asks.first.remaining).to eq(500)
      expect(@book.asks.count).to eq(2)
      expect(@book.spread).to eq(30000)
      expect(@book.ask).to eq(80000)
      expect(@book.bid).to eq(50000)
    end

    it 'should execute an ask properly' do
      @book.receive_order(Gekko::Order.new(:ask, random_id, 2500, 30000))
      expect(@book.bids.first.price).to eq(30000)
      expect(@book.bids.first.remaining).to eq(500)
      expect(@book.bids.count).to eq(2)
      expect(@book.spread).to eq(30000)
      expect(@book.ask).to eq(60000)
      expect(@book.bid).to eq(30000)
    end

    it 'should refuse too precise prices' do
      expect { @book.receive_order(Gekko::Order.new(:ask, random_id, 1000, @book.tick_size + 1)) }.to raise_error do |error|
        expect(error).to be_a(Gekko::TickSizeMismatch)
      end
    end

    it 'should reject duplicate IDs' do
      order = Gekko::Order.new(:ask, random_id, 1000, @book.tick_size)
      2.times { @book.receive_order(order) }
      expect(@book.tape.last[:type]).to eql(:reject)
    end

    it 'should return the ticker' do
      @book.receive_order(Gekko::Order.new(:ask, random_id, 2500, 30000))
      expect(@book.ticker).to eql({
        ask:    60000,
        bid:    30000,
        last:   30000,
        spread: 30000
      })
    end
  end

end
