module Sinatra
  module Rush
    class Configuration

      def initialize(options = {}, &blk)
        @options = options
        @options ||= {}
        blk.call self
        @options
      end

      def set(k, v)
        @options[k] = v
      end

      def set?(k,v)
        @options[k] ||= v
      end

      def get(k)
        @options[k]
      end

      def blinding(*system_fun)
        @options[:blinding] = system_fun.map(&:to_sym)
      end

    end
  end
end








