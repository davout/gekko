require_relative '../spec_helper'

describe 'Gekko::Matcher' do
  describe '#new' do
    it 'should start by waiting for an order' do
      redis = mock(Redis::Client)

      Gekko::Matcher.any_instance.stub(:redis).and_return(redis)
      Gekko::Matcher.any_instance.stub(:execute_order)
      Gekko::Models::Order.stub(:parse)

      Gekko::Matcher.any_instance.should_receive(:terminated).exactly(2).times.and_return(false, true)
      redis.should_receive(:blpop).once.with('btcxrp:orders')

      Gekko::Matcher.new('BTCXRP').match!
    end
  end

  describe '#execute_order' do
    it 'should add orders to the book' do
      matcher = Gekko::Matcher.new('BTCXRP')
      matcher.redis.should_receive(:zadd).once.with('btcxrp:book:buy', 100, '{"amount":100,"price":100,"type":"buy"}')
      matcher.execute_order(Gekko::Models::Order.new('buy', 100, 100))
    end
  end
end

