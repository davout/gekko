require_relative '../spec_helper'

describe 'Gekko' do
  describe '.shutdown' do

    before do
      Gekko::Matcher.any_instance.stub(:match!)
    end

    it 'should shutdown properly' do
      Gekko::Matcher.should_receive(:fork!).and_return([1,2])

      Gekko.start! do 

        EventMachine.should_receive(:stop).once.and_call_original
        Process.should_receive(:kill).twice
        Process.should_receive(:waitall).once

        EventMachine.next_tick do
          Gekko.shutdown
        end
      end
    end
  end
end

