module Gekko
  module Commands
    class Ticker < ::Gekko::Command

      attr_accessor :pair

      def initialize(data, connection)
        self.pair = data['pair']
        super(data, connection)
      end

      def execute
        Gekko::Models::Ticker.get_json(@pair, @connection.redis) do |ticker|
          @connection.send_data(ticker)
        end
      end

    end
  end
end

