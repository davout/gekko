module Gekko
  module Commands
    class Authenticate < ::Gekko::Command

      def initialize(*args)
        super(*args)
      end

      def execute 
        @connection.logger.info("Authenticated account #{@account}")
        @connection.account = @account
      end

    end
  end
end

