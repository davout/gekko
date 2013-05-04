require_relative '../../spec_helper'

describe 'Gekko::Commands::Authenticate' do

  describe '#execute' do
    before do
      @connection = Gekko::Connection.new(nil)
      @connection.stub!(:logger).and_return(mock(Object).as_null_object)
      @command = Gekko::Commands::Authenticate.new({ 'account' => '5318BF75-683C-4F74-9C8E-E5FA9B154B28' }, @connection) 
    end

    it 'should set the account on the connection' do
      @connection.should_receive(:account=).with('5318BF75-683C-4F74-9C8E-E5FA9B154B28').and_call_original
      @command.execute
    end
  end
end
