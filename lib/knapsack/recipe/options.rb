module Knapsack
  class Recipe
    class Options
      DEFAULT = {
        :configure             => "configure",
        :makefile              => "Makefile",
        :ignore_extract_errors => false,
        :verbose               => false
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

      def ignore_extract_errors
        @current.fetch(:ignore_extract_errors, DEFAULT[:ignore_extract_errors])
      end

      def ignore_extract_errors=(value)
        @current[:ignore_extract_errors] = value
      end

      def verbose
        @current.fetch(:verbose, DEFAULT[:verbose])
      end

      def verbose=(value)
        @current[:verbose] = value
      end
    end
  end
end
