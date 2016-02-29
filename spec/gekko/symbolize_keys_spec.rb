require_relative '../spec_helper'

class DummySymbolizeKeys
  include Gekko::SymbolizeKeys
end

describe Gekko::SymbolizeKeys do
  let(:o) { DummySymbolizeKeys.new }

  describe '#symbolize_keys' do
    it 'should correctly handle an empty hash' do
      expect(o.symbolize_keys({})).to eql({})
    end

    it 'should handle a complex hash' do
      expect(o.symbolize_keys({ 'test' => [ { 'hello' => 'world' }] })).
        to eql({ test: [{ hello: 'world' }] })
    end
  end

end

