require_relative '../spec_helper'

describe 'Gekko::Matcher' do
  describe '#new' do
    it 'should start by waiting for an order' do
      redis = mock(Redis::Client)

      Gekko::Matcher.any_instance.stub(:redis).and_return(redis)
      Gekko::Matcher.any_instance.should_receive(:terminated).exactly(2).times.and_return(false, true)

      redis.should_receive(:blpop).once.with('btcxrp:orders')

      Gekko::Matcher.new('BTCXRP')
    end
  end
end

