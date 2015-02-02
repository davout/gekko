require_relative './spec_helper'

describe Gekko::Tape do

  before do
    @tape = Gekko::Tape.new
  end

  describe '#next' do
    it 'should return the next unread event' do
      2.times { @tape << {} }
      expect(@tape.next).to(eql({ sequence: 0 })) 
      expect(@tape.next).to(eql({ sequence: 1 })) 
      expect(@tape.next).to be_nil
    end
  end


  describe '#volume_24h' do
    it 'should report volume on trades that just happened' do
      execution = { type: :execution, price: 2, base_size: 42, quote_size: 84, time: Time.now.to_f }
      expect { @tape << execution }.to change { @tape.volume_24h }.from(0).to(42) 
      expect { @tape << execution }.to change { @tape.volume_24h }.from(42).to(84) 
    end

    it 'should not take older than 24h trades into account' do
      old_ex = { type: :execution, price: 1, base_size: 42, quote_size: 42, time: Time.now.to_f }
      expect { @tape << old_ex }.to change { @tape.volume_24h }.from(0).to(42) 

      Timecop.freeze(Time.at(Time.now + 3600 * 25)) do
        old_ex = { type: :execution, price: 1, base_size: 50, quote_size: 50, time: Time.now.to_f }
        expect { @tape << old_ex }.to change { @tape.volume_24h }.from(0).to(50) 
      end
    end
  end

end
