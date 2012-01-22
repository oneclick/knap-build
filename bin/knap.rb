require "knapsack/recipe"
require "knapsack/recipe_loader"
require "knapsack/utils"

recipe_file = Dir.glob("var/**/*.knapfile").sort.first

recipe = Knapsack::RecipeLoader.load_from recipe_file

puts recipe.inspect
