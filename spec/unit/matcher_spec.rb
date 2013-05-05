require_relative '../spec_helper'

describe 'Gekko::Matcher' do
  describe '.start!' do
    it 'should fork one matching process per pair' do
      Gekko::Matcher.should_receive(:fork).exactly(4).times
      Gekko::Matcher.fork! ['BTCXRP', 'BTCUSD', 'BTCEUR', 'BTCLTC'], nil
    end
  end

  describe '#new' do

    before do
      @redis = mock(Redis::Client)
      @order = Gekko::Models::Order.new('BTCXRP', 'buy', 100, 100, '01647f52-152b-43ea-a38e-d559eb3a5779')

      Gekko::Matcher.any_instance.stub(:redis).and_return(@redis)
      Gekko::Matcher.any_instance.stub(:connect_redis)
      Gekko::Matcher.any_instance.stub(:execute_order)
      Gekko::Models::Order.stub(:find).and_return(@order)
    end

    it 'should start by waiting for an order' do
      Gekko::Matcher.any_instance.should_receive(:terminated).exactly(2).times.and_return(false, true)
      @redis.should_receive(:brpop).once.with('btcxrp:orders', Gekko::Matcher::BRPOP_TIMEOUT).and_return('01647f52-152b-43ea-a38e-d559eb3a5779')

      Gekko::Matcher.new('BTCXRP', nil).match!
    end
  end

  describe '#execute_order' do

    before do
      @order   = Gekko::Models::Order.new('BTCXRP', 'buy', 100, 100, '01647f52-152b-43ea-a38e-d559eb3a5779')
      Redis.stub(:connect).and_return(mock(Object).as_null_object)
      @matcher = Gekko::Matcher.new('BTCXRP', nil)
    end

    it 'should add orders to the book' do
      @matcher.redis.should_receive(:zadd).once.with('btcxrp:book:buy', 100, @order.id)
      @matcher.redis.should_receive(:set).once.with(@order.id, @order.to_json)

      @matcher.execute_order(@order)
    end

  end
end

