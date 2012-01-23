require "knapsack"

files = Dir.glob("#{Knapsack.var_root}/recipes/**/*.knapfile").sort

recipes = files.collect { |f| Knapsack::RecipeLoader.load_from(f) }

recipe_name = ARGV.pop
recipe = recipes.find { |r| r.name == recipe_name }

if recipe
  recipe.cook
else
  abort "Recipe '#{recipe_name}' not found."
end
