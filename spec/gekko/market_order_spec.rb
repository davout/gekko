require_relative '../spec_helper'

describe Gekko::MarketOrder do

  describe '#new' do
    it 'should reject an ask if it does not specify the size' do
      expect { Gekko::MarketOrder.new(:ask, random_id, nil, 1_000_0000) }.to raise_error do |err|
        expect(err.message).to match(/Size must be provided for a market ask/)
      end
    end

    it 'should reject a bid if it does not specify a quote margin' do
      expect { Gekko::MarketOrder.new(:bid, random_id, 1_0000_0000, nil) }.to raise_error do |err|
        expect(err.message).to match(/Quote currency margin must be provided for a market bid/)
      end
    end
  end

end

