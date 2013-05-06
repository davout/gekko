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
end
