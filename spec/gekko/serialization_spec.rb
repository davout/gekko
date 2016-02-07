require_relative './spec_helper'

describe Gekko::Serialization do

  let(:market_order) { Gekko::MarketOrder.new(:bid, UUID.random_create, 1, 1) }

  describe '.deserialize' do
    it 'should correctly deserialize a market order' do
      deserialized = Gekko::Order.deserialize(market_order.serialize)
    end
  end

end

