# encoding: UTF-8

require "logger"

module Knapsack
  class Logger < ::Logger
    class Formatter < ::Logger::Formatter
      def call(severity, time, progname, msg)
        "--> %s\n" % msg
      end
    end

    def initialize(logdev, shift_age = 0, shift_size = 1048576)
      super
      @level = Logger::INFO
      @formatter = Formatter.new
    end
  end
end
