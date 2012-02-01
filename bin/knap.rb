# encoding: UTF-8

require "knapsack"
require "optparse"

files = Dir.glob("#{Knapsack.var_root}/recipes/**/*.knapfile").sort

files.each do |f|
  Knapsack::Recipe.add_recipe(f)
end

options = {}
opts = OptionParser.new do |opts|
  opts.on("-p", "--platform PLATFORM", "Specify the target platform") do |v|
    options[:platform] = v
  end

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
end
opts.parse!(ARGV)

recipe_name = ARGV.pop
recipe = Knapsack::Recipe.find_by_name recipe_name

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
else
  abort "Recipe '#{recipe_name}' not found."
end
