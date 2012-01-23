require "knapsack"

files = Dir.glob("#{Knapsack.var_root}/recipes/**/*.knapfile").sort

files.each do |f|
  recipe = Knapsack::RecipeLoader.load_from(f)
  Knapsack.recipes[recipe.name][recipe.version] = recipe
end

recipe_name = ARGV.pop
recipe = Knapsack::Recipe.find recipe_name

if recipe
  recipe.cook
else
  abort "Recipe '#{recipe_name}' not found."
end
