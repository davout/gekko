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

end
