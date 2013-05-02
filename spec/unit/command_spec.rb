require_relative '../spec_helper'

describe 'Gekko::Command' do
  describe '.parse' do
    it 'should parse a command' do
      cmd = '{ "command" : "order", "args" : { "category" : "buy", "amount" : 100000000 }}'
      Gekko::Command.parse(cmd).should be_an_instance_of Gekko::Command
    end

    it 'should fail to parse invalid JSON' do
      expect { Gekko::Command.parse('foo') }.to raise_error
    end
  end

  describe '#new' do
    it 'should create a command' do
      data = { "command" => "order", "args" => { "category" => "buy", "amount" => 100000000 }}
      Gekko::Command.new(data).should be_an_instance_of Gekko::Command
    end

    it 'should fail to instantiate invalid command' do
      data = { "command" => "invalid" }
      expect { Gekko::Command.new(data) }.to raise_error
    end
  end
end
