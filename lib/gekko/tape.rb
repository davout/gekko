module Gekko
  class Tape

    attr_accessor :events, :logger

    def initialize(logger = nil)
      @events = []
      @logger = logger
    end

    def [](index)
      events[index]
    end

    def <<(item)
      item[:sequence] = events.length
      logger && logger.info(item)
      events << item
    end

  end
end
