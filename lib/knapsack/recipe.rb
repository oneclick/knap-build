# encoding: UTF-8

require "rbconfig"
require "ostruct"

require "knapsack/platform"
require "knapsack/recipe/loader"
require "knapsack/recipe/helpers/autotools"
require "knapsack/recipe/helpers/fetcher"
require "knapsack/recipe/helpers/patch"

# hack
require "knapsack/recipe/dependency"

module Knapsack
  class Recipe
    include Helpers::Autotools
    include Helpers::Fetcher
    include Helpers::Patch

    DEFAULT_OPTIONS = {
      :configure             => "configure",
      :makefile              => "Makefile",
      :configure_args        => [],
      :make_args             => [],
      :ignore_extract_errors => false,
      :verbose               => false
    }

    attr_reader :name, :version
    attr_writer :logger, :loaded_from

    def self._all
      @@all ||= []
    end

    def self._resort!
      @@all.sort! { |a, b|
        names = a.name <=> b.name
        next names if names.nonzero?
        b.version <=> a.version
      }
    end

    def self.add_recipe(filename)
      recipe = Loader.load_from(filename)

      _all << recipe
      _resort!
    end

    def self.find_by_name name, *requirements
      requirements = Gem::Requirement.default if requirements.empty?
      dependency = Gem::Dependency.new(name, *requirements)

      candidates = _all.select { |r|
        dependency.match? r.name, r.version
      }.sort_by { |r| r.version }

      candidates.last
    end

    def initialize(name, version, &block)
      @name         = name
      @version      = Gem::Version.new(version)
      @sequence     = []
      @actions      = {}
      @activated    = false
      @activate_dependencies = false

      @dependencies = []

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

    def platform=(value)
      @target = @host = value
      @platform = nil
    end

    def platform
      @platform ||= Platform.new(@target, @host)
    end

    def options
      @options ||= OpenStruct.new(DEFAULT_OPTIONS)
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
      activate_dependencies
      say "About to process %s version %s (%s)" % [name, version, platform.simplified]

      sequence.each do |action|
        perform action
      end

      say "Done."
    end

    def pending?
      sequence.any? { |name| not File.exists?(extract_path(".#{name}.stamp")) }
    end

    def run(cmd, opt = {})
      flags = {
        :err => [:child, :out], :out => IO::NULL,
        :chdir => work_path,
      }
      if opt.fetch(:nocd, false)
        flags.delete(:chdir)
      end

      if opt.fetch(:verbose, options.verbose)
        puts cmd
        flags[:out] = STDOUT
      end

      # additional environment variables
      env = opt.fetch(:env, {})

      pid = Process.spawn(env, cmd, flags)
      _, status = Process.wait2(pid)

      unless status.success?
        raise "Failed to execute '#{cmd}', exitstatus: #{status.exitstatus}"
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

    def depends_on(depname, *requirements)
      if depname == name
        raise ArgumentError.new("Recipe for '#{name}' can't depend on itself.")
      end

      dep = ::Gem::Dependency.new(depname, *requirements)

      @dependencies << dep
    end

    def dep_list
      @dependencies
    end

    def dependencies
      return [] if @dependencies.empty?

      @dependencies.collect { |dep|
        self.class.find_by_name(dep.name, dep.requirement)
      }.compact
    end

    def activate(target = nil)
      # adjust platform if provided
      self.platform = target if target

      raise_if_conflicts

      return false if Knapsack.activated_recipes[name]

      if pending?
        cook
      else
        activate_dependencies
      end

      activate_paths

      Knapsack.activated_recipes[name] = self
      @activated = true
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
        "Fetching files..."
      when :extract
        "Extracting files into work directory"
      when :configure
        "Configuring"
      when :compile
        "Compiling"
      when :install
        "Staging"
      else
        "Performing '#{action}'"
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
      Knapsack.extract_path(name, version, platform, filename)
    end

    def work_path(filename = nil)
      Knapsack.work_path(name, version, platform, filename)
    end

    def install_path(filename = nil)
      Knapsack.install_path(name, version, platform, filename)
    end

    def recipe_path(filename = nil)
      dirname = File.dirname(@loaded_from)
      Knapsack.recipe_path(dirname, filename)
    end

    def raise_if_conflicts
      other = Knapsack.activated_recipes[name]

      if other and version != other.version
        msg = "Can't activate #{name} version #{version}, already activated version #{other.version}"
        raise msg
      end
    end

    def activate_paths
      vars = {
        "PATH"         => install_path("bin"), # executables
        "CPATH"        => install_path("include"), # headers
        "LIBRARY_PATH" => install_path("lib"), # linking libraries
      }.reject { |_, path| !File.directory?(path) }

      say "Activating #{name} version #{version} (#{platform.simplified})..."
      vars.each do |var, path|
        # turn into a valid Windows path (if required)
        path.gsub!(File::SEPARATOR, File::ALT_SEPARATOR) if File::ALT_SEPARATOR

        # save current variable value
        old_value = ENV[var] || ''

        unless old_value.include?(path)
          ENV[var] = "#{path}#{File::PATH_SEPARATOR}#{old_value}"
        end
      end

      # rely on LDFLAGS when cross-compiling
      if vars.has_key?("LIBRARY_PATH") && platform.cross?
        path = vars["LIBRARY_PATH"]

        old_value = ENV.fetch("LDFLAGS", "")

        unless old_value.include?(path)
          ENV["LDFLAGS"] = "-L#{path} #{old_value}".strip
        end
      end
    end

    def activate_dependencies
      return if @dependencies.empty?
      return if @activated_dependencies

      say "Computing and activating dependencies for #{name} version #{version} (#{platform.simplified})"
      dependencies.each do |recipe|
        # activate the recipe for the same platform
        recipe.activate platform.target
      end

      @activated_dependencies = true
    end
  end
end
