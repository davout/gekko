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
      @book.execute_order(Gekko::Order.new(random_id, 1, 1, Time.now.to_i))
      @book.execute_order(Gekko::Order.new(random_id, 1, 2, Time.now.to_i))
      expect(@book.bid).to eql(2)
    end
  end

  describe '#ask' do
    it 'should be nil when no order is present' do
      expect(@book.ask).to be_nil
    end

    it 'should return the price of the best bid' do
      @book.execute_order(Gekko::Order.new(random_id, -1, 1, Time.now.to_i))
      @book.execute_order(Gekko::Order.new(random_id, -1, 2, Time.now.to_i))
      expect(@book.ask).to eql(1)
    end
  end

  describe '#execute_order' do
  end

end
