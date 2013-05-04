require_relative '../spec_helper'

describe 'Gekko::Command' do

  before(:each) do
    logger     = mock(Logger)
    @connection = mock(Gekko::Connection)

    logger.stub!(:error)
    @connection.stub(:logger).and_return(logger)
    @connection.stub(:account).and_return('5318BF75-683C-4F74-9C8E-E5FA9B154B28')
  end

  describe '.parse' do
    it 'should parse a command' do
      cmd = { "command" => "order", "args" => { "type" => "buy", "amount" => 100000000, "pair" => "BTCXRP" }}
      Gekko::Command.build(cmd, @connection).should be_kind_of Gekko::Command
    end

    it 'should fail to parse invalid JSON' do
      expect { Gekko::Command.build('foo', @connection) }.to raise_error
    end
  end

end
