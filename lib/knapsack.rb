require "knapsack/recipe"
require "knapsack/recipe_loader"
require "knapsack/utils"

module Knapsack
  def root
    @root ||= File.expand_path "../..", __FILE__
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

  def extract_path(name, version, filename = nil)
    File.join *[tmp_root, "work", name, version, filename].compact
  end
  module_function :extract_path

  def work_path(name, version, filename = nil)
    # first directory from extract_path
    base = Dir.glob("#{extract_path(name, version)}/*").find { |d|
      File.directory?(d)
    }

    File.join *[base, filename].compact
  end
  module_function :work_path

  def install_path(name, version, filename = nil)
    File.join *[var_root, "software", name, version, filename].compact
  end
  module_function :install_path
end
