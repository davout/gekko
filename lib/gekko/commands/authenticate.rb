module Gekko
  module Commands
    class Authenticate < ::Gekko::Command

      def initialize(data, connection)
        @account = data['account']
        super
      end

      def execute 
        @connection.logger.info("Authenticated account #{@account}")
        @connection.account = @account
      end

    end
  end
end

