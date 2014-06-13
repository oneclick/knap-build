# encoding: UTF-8

require "knapsack/recipe"
require "knapsack/utils"
require "knapsack/logger"

module Knapsack
  def logger
    @logger ||= Knapsack::Logger.new(STDOUT)
  end
  module_function :logger

  def activated_recipes
    @activated_recipes ||= {}
  end
  module_function :activated_recipes

  def root
    @root ||= begin
      file = defined?(ExerbRuntime) ? ExerbRuntime.filepath : __FILE__
      File.expand_path "../..", file
    end
  end
  module_function :root

  def var_root
    File.join root, "var", "knapsack"
  end
  module_function :var_root

  def tmp_root
    File.join root, "tmp", "knapsack"
  end
  module_function :tmp_root

  def distfiles_path(name, filename = nil)
    File.join *[var_root, "distfiles", name, filename].compact
  end
  module_function :distfiles_path

  def packages_path(name, filename = nil)
    File.join *[var_root, "packages", name, filename].compact
  end
  module_function :packages_path

  def extract_path(name, version, platform, filename = nil)
    File.join *[tmp_root, "work", platform.simplified, name, version.to_s, filename].compact
  end
  module_function :extract_path

  def work_path(name, version, platform, filename = nil)
    # first directory from extract_path
    base = Dir.glob("#{extract_path(name, version, platform)}/*").find { |d|
      File.directory?(d)
    }

    File.join *[base, filename].compact
  end
  module_function :work_path

  def install_path(name, version, platform, filename = nil)
    File.join *[var_root, "software", platform.simplified, name, version.to_s, filename].compact
  end
  module_function :install_path

  def recipe_path(path, filename = nil)
    File.join *[path, filename].compact
  end
  module_function :recipe_path
end
