require_relative '../spec_helper'

describe Gekko::Order do

  describe '#new' do
    it 'should not allow both stop_price and stop_percent to be set simultaneously' do
      expect { Gekko::Order.new(:ask, random_id, random_id, 1, { stop_price: 1, stop_percent: 1 }) }.
        to raise_error('Stop orders must specify exactly one of either price or trailing percentage.')
    end
  end

  describe '#stop?' do
    it 'should return true if either one of stop_price or stop_percentage is set' do
      expect(Gekko::Order.new(:ask, random_id, random_id, 1, { stop_percent: 1 }).stop?).
        to be_truthy

      expect(Gekko::Order.new(:ask, random_id, random_id, 1, { stop_price: 1 }).stop?).
        to be_truthy
    end

    it 'should return false if neither one of stop_price or stop_percentage is set' do
      expect(Gekko::Order.new(:ask, random_id, random_id, 1).stop?).
        to be_falsey
    end
  end

  describe '#should_trigger?' do
    it 'should raise an error when called for a non-stop order' do
      expect { Gekko::Order.new(:ask, random_id, random_id, 1).should_trigger? }.
        to raise_error("Called Order#should_trigger? on a non-stop order")
    end

    it 'should return true for an ask when the last price is below the stop price' do
      expect(book.ticker).to receive(:last).once.and_return(1_0000_0000)
      expect(Gekko::Order.new(:ask, random_id, random_id, 1, { stop_price:  5000_0000 }).should_trigger?).
        to be_truthy
    end

    it 'should return false for an ask when the last price is above the stop price' do
      expect(book.ticker).to receive(:last).once.and_return(1_0000_0000)
      expect(Gekko::Order.new(:ask, random_id, random_id, 1, { stop_price: 2_0000_0000 }).should_trigger?).
        to be_falsey
    end

    it 'should return true for a bid when the last price is above the stop price' do
      expect(book.ticker).to receive(:last).once.and_return(1_0000_0000)
      expect(Gekko::Order.new(:ask, random_id, random_id, 1, { stop_price:  2_0000_0000 }).should_trigger?).A
      to be_truthy
    end

    it 'should return false for a bid when the last price if below the stop price' do
      expect(book.ticker).to receive(:last).once.and_return(1_0000_0000)
      expect(Gekko::Order.new(:ask, random_id, random_id, 1, { stop_price:  5000_0000 }).should_trigger?).
        to be_falsey
    end
  end


end

