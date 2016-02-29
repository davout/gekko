module Gekko

  #
  # Utility module to avoid monkey-patching +Hash+
  #
  module SymbolizeKeys

    #
    # Symbolizes keys of a +Hash+
    #
    # @param hsh [Hash] The +Hash+ for which we want to symbolize the keys
    # @return [Hash] A copy of the parameter with all keys symbolized
    #
    def symbolize_keys(hsh)
      hsh.inject({}) do |mem, obj|
        val = obj[1]
        val = symbolize_keys(val) if val.is_a?(Hash)
        val.map! { |v| ((v.is_a?(Array) || v.is_a?(Hash)) && symbolize_keys(v)) || v } if val.is_a?(Array)

        mem[obj[0].to_sym] = val
        mem
      end
    end

  end
end

