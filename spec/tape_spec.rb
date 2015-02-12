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
        new_ex = { type: :execution, price: 1, base_size: 50, quote_size: 50, time: Time.now.to_f }
        expect { @tape << new_ex }.to change { @tape.volume_24h }.from(0).to(50) 
      end
    end
  end

  describe '#high_24h' do
    it 'should not take highs older than 24h into account' do
      old_ex = { type: :execution, price: 1000, base_size: 42, quote_size: 42, time: Time.now.to_f }
      expect { @tape << old_ex }.to change { @tape.high_24h }.from(nil).to(1000) 

      Timecop.freeze(Time.at(Time.now + 3600 * 25)) do
        new_ex = { type: :execution, price: 500, base_size: 50, quote_size: 50, time: Time.now.to_f }
        expect { @tape << new_ex }.to change { @tape.low_24h }.from(nil).to(500) 
      end
    end

    it 'should update the high according to executions' do
      old_ex_1 = { type: :execution, price: 1000, base_size: 42, quote_size: 42, time: Time.now.to_f }
      expect { @tape << old_ex_1 }.to change { @tape.high_24h }.from(nil).to(1000) 

      old_ex_2 = { type: :execution, price: 900, base_size: 42, quote_size: 42, time: Time.now.to_f }
      expect { @tape << old_ex_2 }.not_to change { @tape.high_24h }

      old_ex_3 = { type: :execution, price: 1100, base_size: 42, quote_size: 42, time: Time.now.to_f }
      expect { @tape << old_ex_3 }.to change { @tape.high_24h }.from(1000).to(1100)
    end
  end

  describe '#low_24h' do
    it 'should update the low according to executions' do
      old_ex_1 = { type: :execution, price: 1000, base_size: 42, quote_size: 42, time: Time.now.to_f }
      expect { @tape << old_ex_1 }.to change { @tape.low_24h }.from(nil).to(1000) 

      old_ex_2 = { type: :execution, price: 1100, base_size: 42, quote_size: 42, time: Time.now.to_f }
      expect { @tape << old_ex_2 }.not_to change { @tape.low_24h }

      old_ex_3 = { type: :execution, price: 900, base_size: 42, quote_size: 42, time: Time.now.to_f }
      expect { @tape << old_ex_3 }.to change { @tape.low_24h }.from(1000).to(900)
    end

    it 'should not take lows older than 24h into account' do
      old_ex = { type: :execution, price: 500, base_size: 42, quote_size: 42, time: Time.now.to_f }
      expect { @tape << old_ex }.to change { @tape.low_24h }.from(nil).to(500) 

      Timecop.freeze(Time.at(Time.now + 3600 * 12)) do
        new_ex = { type: :execution, price: 750, base_size: 50, quote_size: 50, time: Time.now.to_f }
        expect { @tape << new_ex }.not_to change { @tape.low_24h }
        expect { Timecop.travel(Time.at(Time.now + 3600 * 13)) }.to change { @tape.low_24h }.from(500).to(750)
      end

      Timecop.return
    end
  end

end

