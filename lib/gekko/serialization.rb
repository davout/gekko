require 'gekko/symbolize_keys'

require 'oj'
Oj.default_options = { mode: :compat }

module Gekko

  #
  # Handles JSON serialization and deserialization
  #
  module Serialization

    #
    # Make our class methods available directly on +Gekko::Order+
    #
    def self.included(base)
      base.extend(ClassMethods)
    end

    #
    # De-serialization methods to be made available directly on +Gekko::Order+
    #
    module ClassMethods

      include SymbolizeKeys

      #
      # Deserializes a +Gekko::Order+ subclass from JSON
      #
      # @param serialized [String] The JSON string
      # @return [Gekko::Order] The deserialized trade order
      #
      def deserialize(serialized)
        from_hash(symbolize_keys(Oj.load(serialized)))
      end
    end

    #
    # Serializes a +Gekko::Order+ as JSON
    #
    # @param order [Gekko::Order] The order to serialize
    # @return [String] The JSON string
    #
    def serialize
      Oj.dump(to_hash)
    end

  end
end

