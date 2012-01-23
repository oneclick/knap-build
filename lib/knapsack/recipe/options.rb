module Knapsack
  class Recipe
    class Options
      DEFAULT = {
        :configure => "configure",
        :makefile  => "Makefile"
      }

      def initialize
        @current = {}
      end

      def configure
        @current.fetch(:configure, DEFAULT[:configure])
      end

      def configure=(value)
        @current[:configure] = value
      end

      def makefile
        @current.fetch(:makefile, DEFAULT[:makefile])
      end

      def makefile=(value)
        @current[:makefile] = value
      end
    end
  end
end
