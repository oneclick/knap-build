# encoding: UTF-8

require "knapsack"
require "optparse"

# find and load recipes
files = Dir.glob("#{Knapsack.var_root}/recipes/**/*.knapfile").sort
files.each do |f|
  Knapsack::Recipe.add_recipe(f)
end

options = {}

# determine current platform from gcc -v
platform_re = /^Target\: (.*)$/

output = `gcc -v 2>&1`
if m = output.match(platform_re)
  # deal with special "mingw32" platform (mingw.org)
  if m[1] == "mingw32"
    options[:platform] = "i686-pc-mingw32"
  else
    options[:platform] = m[1]
  end
end

plat = Knapsack::Platform.new(options[:platform])
puts "--> Detected platform: #{plat.target} (#{plat.simplified})"

opts = OptionParser.new do |opts|
  opts.on("-p", "--platform PLATFORM", "Specify the target platform") do |v|
    options[:platform] = v
  end

  opts.on("-v VERSION", "--version VERSION", "Specify the desired version") do |v|
    options[:version] = v
  end

  opts.on("-V", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
end
opts.parse!(ARGV)

recipe_name = ARGV.pop
recipe_version = options.fetch(:version, ">= 0")

recipe = Knapsack::Recipe.find_by_name recipe_name, recipe_version

exit if defined?(Exerb)

if recipe
  # set options
  if options.has_key?(:verbose)
    recipe.options.verbose = options[:verbose]
  end

  if options.has_key?(:platform)
    recipe.platform = options[:platform]
  end

  if recipe.pending?
    recipe.cook
  end
  recipe.activate

  Knapsack::Utils.package recipe
else
  abort "Recipe '#{recipe_name}' not found."
end
