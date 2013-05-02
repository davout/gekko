require_relative '../../spec_helper'

describe 'Gekko::Commands::Order' do

  before(:each) do
    cmd = '{ "command" : "order", "args" : { "category" : "buy", "amount" : 100000000, "pair" : "BTCEUR", "type" : "buy" }}'
    logger = mock(Logger).as_null_object
    @connection = mock(Gekko::Connection)
    @connection.stub(:logger).and_return(logger)
    @c = Gekko::Command.build(cmd, @connection)
  end

  describe '#to_json' do
    it 'should call Oj.dump' do
      Oj.should_receive(:dump).once.and_call_original
      @c.to_json
    end

    it 'should render the command as JSON' do  
      Oj.load(@c.to_json).should eql(Oj.load('{"pair":"BTCEUR", "amount":100000000, "price":null, "type":"buy"}'))
    end
  end

  describe '#execute' do
    before(:each) do
      @redis = mock(EventMachine::Hiredis)
      @connection.stub(:redis).and_return(@redis)
    end

    it 'should push the order on a redis queue' do
      @redis.should_receive(:push_tail).once.with('btceur:orders', '{"pair":"BTCEUR","amount":100000000,"price":null,"type":"buy"}')
      @c.execute
    end
  end

end
