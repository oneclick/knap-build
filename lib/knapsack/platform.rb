# encoding: UTF-8

module Knapsack
  class Platform
    RE_X86    = /i\d86/
    RE_X64    = /(x86_|amd)64/
    RE_MINGW  = /mingw32$/
    RE_DARWIN = /darwin/
    RE_LINUX  = /linux(-gnu)?$/

    attr_reader :target, :host

    def initialize(target, host = nil)
      @target = target
      @host = host
    end

    def x86?
      !(@target =~ RE_X86).nil?
    end

    def x64?
      !(@target =~ RE_X64).nil?
    end

    def mingw?
      !(@target =~ RE_MINGW).nil?
    end

    def darwin?
      !(@target =~ RE_DARWIN).nil?
    end

    def linux?
      !(@target =~ RE_LINUX).nil?
    end

    def posix?
      darwin? || linux?
    end

    def native?
      !cross?
    end

    def cross?
      @target != @host
    end

    def simplified
      parts = []

      case
      when x86?
        parts << "x86"
      when x64?
        parts << "x64"
      end

      case
      when mingw?
        parts << "windows"
      end

      parts.join("-")
    end
  end
end
