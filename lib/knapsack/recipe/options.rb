module Knapsack
  class Recipe
    class Options
      DEFAULTS = {
        :makefile => "Makefile"
      }

      def initialize
        @current = {}
      end

      def makefile
        @current.fetch(:makefile, DEFAULTS[:makefile])
      end

      def makefile=(value)
        @current[:makefile] = value
      end
    end
  end
end
