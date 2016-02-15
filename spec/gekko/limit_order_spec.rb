require_relative '../spec_helper'

describe Gekko::LimitOrder do

  describe '.from_hash' do
    subject   { Gekko::LimitOrder }
    let(:hsh) { { side: :bid, id: random_id.to_s, uid: random_id.to_s, price: 1000, size: 42 } }

    it 'should set remaining as the size if not present' do
      expect(subject.from_hash(hsh).remaining).to eql(42)
    end

    it 'should set remaining if present' do
      hsh[:remaining] = 22
      expect(subject.from_hash(hsh).remaining).to eql(22)
    end
  end

end

