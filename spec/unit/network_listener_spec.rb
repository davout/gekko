require_relative '../spec_helper'

describe 'Gekko::Server' do
  describe '#new' do
    it 'should fail to start without a running reactor' do
      EventMachine.reactor_running?.should be_false
      expect { Gekko::Server.new }.to raise_error
    end

    it 'should fork one matching process per pair' do
      with_reactor do
        Gekko::Server.any_instance.should_receive(:fork).exactly(4).times
        Gekko::Server.new('0.0.0.0', 9999, ['BTCXRP', 'BTCUSD', 'BTCEUR', 'BTCLTC'])
      end
    end
  end

  describe '#shutdown' do
    it 'should shutdown properly' do
      EventMachine.run do
        server = Gekko::Server.new('0.0.0.0', 9999, ['BTCUSD'])

        EventMachine.should_receive(:stop).once.and_call_original
        Process.should_receive(:kill).once
        Process.should_receive(:waitall).once

        server.shutdown
      end
    end
  end
end

