require "rbconfig"
require "knapsack/platform"
require "knapsack/recipe/options"

module Knapsack
  class Recipe
    attr_reader :name, :version

    def initialize(name, version, &block)
      @name     = name
      @version  = version
      @sequence = []
      @actions  = {}

      # default Platform host and target to current
      @host = @target = RbConfig::CONFIG["target"]

      instance_exec &block
    end

    def sequence(*args)
      return @sequence if args.empty?
      @sequence = args
    end

    def platform
      @platform ||= Platform.new(@target, @host)
    end

    def options
      @options ||= Options.new
    end

    def action(name, &block)
      @actions[name] = block
    end

    def actions
      @actions.keys
    end

    def perform(name)
      unless actions.include?(name)
        raise ArgumentError.new("Unknown action #{name}")
      end

      instance_exec &@actions[name]
    end

    def cook
      sequence.each do |action|
        perform action
      end
    end

    def run(cmd)
      pid = Process.spawn(cmd, :chdir => work_path, :err => :out, :out => IO::NULL)
      _, status = Process.wait2(pid)

      unless status.success?
        raise "Failed to execute '#{cmd}', exitstatus: #{exitstatus}"
      end

      status.success?
    end

    def distfiles_path(filename = nil)
      Knapsack.distfiles_path(name, filename)
    end

    def extract_path
      Knapsack.extract_path(name, version)
    end

    def work_path(filename = nil)
      Knapsack.work_path(name, version, filename)
    end

    def install_path(filename = nil)
      Knapsack.install_path(name, version, filename)
    end
  end
end
