require_relative './spec_helper'

describe Gekko::BookSide do

  describe '#new' do
    it 'should fail with incorrect side' do
      expect { Gekko::BookSide.new(:foo) }.to raise_error('Incorrect side <foo>')
    end
  end

end
