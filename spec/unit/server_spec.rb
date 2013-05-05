require_relative '../spec_helper'

describe 'Gekko::Server' do
  describe '#new' do
    it 'should fail to start without a running reactor' do
      EventMachine.reactor_running?.should be_false
      expect { Gekko::Server.new }.to raise_error
    end
  end

end

