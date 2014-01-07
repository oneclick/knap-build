# encoding: UTF-8

require "knapsack"
require "optparse"

def parse_options(options)
  opts = OptionParser.new do |opts|
    opts.banner = "Usage: knap-build RECIPENAME [options]"

    opts.separator ""
    opts.separator "Specific options:"

    opts.on("--platform PLATFORM", "Specify the target platform") do |v|
      options[:platform] = v
    end

    opts.on("-v", "--version VERSION", "Specify the desired version") do |v|
      options[:version] = v
    end

    opts.on("-V", "--[no-]verbose", "Run verbosely") do |v|
      options[:verbose] = v
    end

    opts.separator ""
    opts.separator "Packaging options:"

    opts.on("--package", "Enable build binary package") do |v|
      options[:package] = v
    end
  end
  opts.parse!(ARGV)
end

def load_recipes
  # find and load recipes
  files = Dir.glob("#{Knapsack.root}/recipes/**/*.knapfile").sort
  files.each do |f|
    Knapsack::Recipe.add_recipe(f)
  end
end

def detect_platform
  # determine current platform from gcc -v
  platform_re = /^Target\: (.*)$/

  output = `gcc -v 2>&1`
  if m = output.match(platform_re)
    # deal with special "mingw32" platform (mingw.org)
    if m[1] == "mingw32"
      "i686-pc-mingw32"
    else
      m[1]
    end
  end
end

options = {}

parse_options options
load_recipes

recipe_name = ARGV.pop
recipe_version = options.fetch(:version, ">= 0")

exit if defined?(Exerb)

if recipe = Knapsack::Recipe.find_by_name(recipe_name, recipe_version)
  unless options.has_key?(:platform)
    options[:platform] = detect_platform

    plat = Knapsack::Platform.new options[:platform]
    puts "--> Detected platform: #{plat.target} (#{plat.simplified})"
  end

  recipe.platform = options[:platform]

  # set options
  if options.has_key?(:verbose)
    recipe.options.verbose = options[:verbose]
  end

  if recipe.pending?
    recipe.cook
  end
  recipe.activate

  if options.fetch(:package, false)
    Knapsack::Utils.package recipe
  end
else
  abort "Recipe '#{recipe_name}' not found."
end
