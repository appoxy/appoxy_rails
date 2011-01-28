module Appoxy
  module UI
    class BindingHack

      def initialize(hash)
        @options = hash
      end

      def get_binding
        binding
      end
    end
  end
end