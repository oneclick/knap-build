# encoding: UTF-8

require "knapsack"

files = Dir.glob("#{Knapsack.var_root}/recipes/**/*.knapfile").sort

files.each do |f|
  Knapsack::Recipe.add_recipe(f)
end

recipe_name = ARGV.pop
recipe = Knapsack::Recipe.find_by_name recipe_name

exit if defined?(Exerb)

if recipe
  if recipe.pending?
    recipe.cook
  end
  recipe.activate
else
  abort "Recipe '#{recipe_name}' not found."
end
