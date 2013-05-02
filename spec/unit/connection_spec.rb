require_relative '../spec_helper'

describe 'Gekko::Connection' do

  before(:each) do
    logger      = mock(Logger)
    redis       = mock(EventMachine::Hiredis)
    @connection = Gekko::Connection.new(nil)

    logger.stub!(:error)
    logger.stub!(:info)

    redis.stub!(:push_tail)

    @connection.stub(:logger).and_return(logger)
    @connection.stub(:redis).and_return(redis)
  end

  describe '#receive_data' do

    before(:each) do 
      @received_data = '{ "command" : "order", "args" : { "amount" : 1, "pair" : "EURUSD", "type" : "buy" } }'
    end

    it 'should build a command from received data' do
      Gekko::Command.should_receive(:build).with(@received_data, @connection).and_call_original
      @connection.receive_data(@received_data)
    end

    it 'should call #execute on the built command' do
      Gekko::Commands::Order.any_instance.should_receive(:execute).once
      @connection.receive_data(@received_data)
    end
  end

end
