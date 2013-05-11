require_relative '../../spec_helper'

describe 'Gekko::Models::Order' do
  before do
    @order_json = Oj.dump({ 'id' => 'foo', 'amount' => 1, 'price' => 1, 'type' => 'buy', 'pair' => 'btceur', 'account' => UUID.generate })
    @redis = mock(Object)
    @redis.stub(:get).and_return(@order_json)
  end

  describe '.find' do
    it 'should fetch an order from redis' do
      Gekko::Models::Order.should_receive(:from_json).once.with(@order_json)
      Gekko::Models::Order.find('foo', @redis)
    end
  end

  describe '.from_json' do
    it 'should build an instance from a json string' do
      Gekko::Models::Order.from_json(@order_json).should be_kind_of Gekko::Models::Order
    end
  end

  describe '#add_to_book)' do
    
    before do
      @bid     = Gekko::Models::Order.new('BTCXRP', 'buy',  10000000, 10000000, '01647f52-152b-43ea-a38e-d559eb3a5779')
      @ask     = Gekko::Models::Order.new('BTCXRP', 'sell', 10000000, 10000000, '01647f52-152b-43ea-a38e-d559eb3a5779')

      @redis = mock(Object).as_null_object
    #  Redis.stub(:connect).and_return(@redis)
    end

    it 'should add a bid to the book' do
      @redis.should_receive(:zadd).once.with('btcxrp:book:buy', 10, @bid.id)
      #@redis.should_receive(:set).once.with(@bid.id, @bid.to_json)

      @bid.add_to_book(@redis)
    end

    it 'should add an ask to the book' do
      @redis.should_receive(:zadd).once.with('btcxrp:book:sell', 0.1, @ask.id)
      #@redis.should_receive(:set).once.with(@ask.id, @ask.to_json)

      @ask.add_to_book(@redis)
    end

  end
end
