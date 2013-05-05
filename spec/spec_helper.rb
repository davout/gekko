require(File.expand_path('../../lib/gekko', __FILE__))

RSpec.configure do |config|
  config.around(:each) do |example|
    silence_logger do
      example.run
    end
  end

  config.before(:each) do
    Redis.connect(Gekko::DEFAULT_REDIS).flushdb
  end

  def silence_logger
    begin
      Gekko::Logger.logging_enabled = false
      Gekko::SynchronousLogger.logging_enabled = false
      yield
    ensure
      Gekko::Logger.logging_enabled = true
      Gekko::SynchronousLogger.logging_enabled = true
    end
  end

  def enable_logger
    Gekko::Logger.logging_enabled = true
    Gekko::SynchronousLogger.logging_enabled = true
    yield
  end

  def with_reactor
    EventMachine.run do
      begin
        yield
      ensure
        EventMachine.stop
      end
    end
  end
end
