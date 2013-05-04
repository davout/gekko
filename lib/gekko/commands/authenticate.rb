module Gekko
  module Commands
    class Authenticate < ::Gekko::Command

      def initialize(data, connection)
        @account = data['account']
        super
      end

      def execute 
        @connection.account = @account
        @connection.logger.info("Authenticated account #{@connection.account}")
        yield({ "info" => "Authenticated as #{@connection.account}"}) if block_given?
      end

    end
  end
end

