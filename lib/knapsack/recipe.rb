require "rbconfig"
require "knapsack/platform"
require "knapsack/recipe/options"
require "knapsack/recipe/helpers/autotools"
require "knapsack/recipe/helpers/fetcher"

module Knapsack
  class Recipe
    include Helpers::Autotools
    include Helpers::Fetcher

    attr_reader :name, :version
    attr_writer :logger

    def initialize(name, version, &block)
      @name     = name
      @version  = version
      @sequence = []
      @actions  = {}

      @before_hooks = Hash.new { |hash, key| hash[key] = [] }
      @after_hooks  = Hash.new { |hash, key| hash[key] = [] }

      # default Platform host and target to current
      @host = @target = RbConfig::CONFIG["target"]

      instance_exec &block
    end

    def logger
      @logger ||= Knapsack.logger
    end

    def sequence(*args)
      return @sequence if args.empty?
      @sequence = args
    end

    def prepend_sequence(*args)
      args.reverse.each do |name|
        @sequence.unshift(name) unless @sequence.include?(name)
      end
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

    def action?(name)
      @actions.has_key?(name)
    end

    def before(name, &block)
      @before_hooks[name] << block
    end

    def after(name, &block)
      @after_hooks[name] << block
    end

    def perform(name)
      unless actions.include?(name)
        raise ArgumentError.new("Unknown action '#{name}'")
      end

      checkpoint name do
        announce name

        trigger :before, name
        instance_exec &@actions[name]
        trigger :after, name
      end
    end

    def trigger(event, action)
      case event
      when :before
        hooks = @before_hooks
      when :after
        hooks = @after_hooks
      else
        raise ArgumentError.new("Invalid event '#{event}'")
      end
      return unless hooks.has_key?(action)

      hooks[action].each do |hook|
        instance_exec &hook
      end
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

    def use(*helpers)
      helpers.each do |name|
        helper = :"define_#{name}"

        unless respond_to?(helper)
          raise ArgumentError.new("Unknown helper '#{name}'")
        end

        send helper
      end
    end

    def checkpoint(name)
      checkfile = extract_path(".#{name}.stamp")

      yield unless File.exists?(checkfile)

      Knapsack::Utils.ensure_tree File.dirname(checkfile)
      File.write(checkfile, Time.now)
    end

    def announce(action)
      msg = case action
      when :download
        "Fetching files for %s %s..."
      when :configure
        "Configuring %s %s"
      when :compile
        "Building %s %s"
      when :install
        "Staging %s %s"
      end

      say msg % [name, version]
    end

    def say(message)
      logger.info message
    end

    def distfiles_path(filename = nil)
      Knapsack.distfiles_path(name, filename)
    end

    def extract_path(filename = nil)
      Knapsack.extract_path(name, version, filename)
    end

    def work_path(filename = nil)
      Knapsack.work_path(name, version, filename)
    end

    def install_path(filename = nil)
      Knapsack.install_path(name, version, filename)
    end
  end
end
