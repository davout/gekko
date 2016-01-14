module Gekko

  #
  # Utility module to avoid monkey-patching +Hash+
  #
  module SymbolizeKeys

    #
    # Symbolizes keys of a non-nested +Hash+
    #
    # @param hsh [Hash] The +Hash+ for which we want to symbolize the keys
    # @return [Hash] A copy of the parameter with all first-level keys symbolized
    #
    def symbolize_keys(hsh)
      hsh.inject({}) { |mem, obj| mem[obj[0].to_sym] = obj[1]; mem }
    end

  end
end

