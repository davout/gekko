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
    @connection.stub(:account).and_return('5318BF75-683C-4F74-9C8E-E5FA9B154B28')
    @connection.stub(:redis).and_return(redis)
  end

  describe '#receive_data' do
    before(:each) do 
      @received_data = '{ "command" : "order", "args" : { "amount" : 1, "pair" : "EURUSD", "type" : "buy" } }'
    end

    it 'should build a command from received data' do
      Gekko::Command.should_receive(:build).with(@received_data, @connection).and_call_original
      Gekko::Commands::Order.any_instance.should_receive(:execute)
      @connection.receive_data(@received_data)
    end

    it 'should call #execute on the built command' do
      Gekko::Commands::Order.any_instance.should_receive(:execute).once
      @connection.receive_data(@received_data)
    end
  end

  describe '#account=' do

    before(:each) do
      @connection = Gekko::Connection.new(nil)
    end

    it 'should not accept an invalid uuid' do
      expect { @connection.account = 'invalid uuid' }.to raise_error
    end

    it 'should accept a valid uuid' do
      @connection.account = 'FA570503-8E7A-4470-9E44-1573C749616C'
      @connection.account.should eql('fa570503-8e7a-4470-9e44-1573c749616c')
    end
  end
end
