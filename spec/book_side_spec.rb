require_relative './spec_helper'

describe Gekko::BookSide do

  before(:each) do
    @bids = Gekko::BookSide.new(:bid)
    @asks = Gekko::BookSide.new(:ask)
  end

  describe '#new' do
    it 'should fail with incorrect side' do
      expect { Gekko::BookSide.new(:foo) }.to raise_error
    end
  end

  describe '#get_depth_at' do
    it 'should report zero for an empty book' do
      expect(@bids.get_depth_at(1)).to eql(0)
      expect(@asks.get_depth_at(1)).to eql(0)
    end
  end

  describe '#set_depth_at' do
    it 'should work on an empty book' do
      @bids.set_depth_at(10, 42)
      @asks.set_depth_at(10, 42)

      expect(@bids.get_depth_at(10)).to eql(42)
      expect(@asks.get_depth_at(10)).to eql(42)
    end

    it 'should insert at the correct positions' do
      @bids.set_depth_at(9, 42)
      @bids.set_depth_at(10, 42)
      @bids.set_depth_at(11, 42)

      @asks.set_depth_at(9, 42)
      @asks.set_depth_at(10, 42)
      @asks.set_depth_at(11, 42)

      expect(@bids.last[0].to_i).to be(9)
      expect(@asks.last[0].to_i).to be(11)

      expect(@bids.first[0].to_i).to be(11)
      expect(@asks.first[0].to_i).to be(9)
    end

    it 'should correctly update a depth' do
      @bids.set_depth_at(9, 42)
      expect(@bids.first[1].to_i).to eql(42)

      @bids.set_depth_at(9, 45)
      expect(@bids.first[1].to_i).to eql(45)

      expect(@bids.length).to be(1)
    end


    it 'should remove element with zero depth' do
      [@bids, @asks].each do |side|
        side.set_depth_at(9, 42)
        side.set_depth_at(10, 42)
        side.set_depth_at(11, 42)

        expect(side.length).to be(3)

        side.set_depth_at(10, 0)
        side.set_depth_at(15, 0)

        expect(side.length).to be(2)
      end
    end

  end


end 
