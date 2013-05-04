require_relative '../../spec_helper'

describe 'Gekko::Commands::Order' do

  before(:each) do
    cmd = '{ "command" : "order", "args" : { "category" : "buy", "amount" : 100000000, "pair" : "BTCEUR", "type" : "buy" }}'
    logger = mock(Logger).as_null_object
    @connection = mock(Gekko::Connection)
    @connection.stub(:logger).and_return(logger)
    @connection.stub(:account).and_return('5318BF75-683C-4F74-9C8E-E5FA9B154B28')
    @c = Gekko::Command.build(cmd, @connection)
  end

  describe '#execute' do
    before(:each) do
      @redis = mock(EventMachine::Hiredis)
      @connection.stub(:redis).and_return(@redis)
    end

    it 'should push the order on a redis queue' do
      deferrable = mock(Object)
      deferrable.should_receive(:callback).and_yield
      @redis.should_receive(:set).once.with(@c.order.id, @c.order.to_json).and_return(deferrable)
      @redis.should_receive(:push_tail).once.with('btceur:orders', @c.order.id)
      @c.execute
    end
  end

end
