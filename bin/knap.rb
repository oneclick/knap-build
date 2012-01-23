require "knapsack"

files = Dir.glob("var/**/*.knapfile").sort

recipes = files.collect { |f| Knapsack::RecipeLoader.load_from(f) }

recipe_name = ARGV.pop
puts :recipe_name => recipe_name

recipe = recipes.find { |r| r.name == recipe_name }

if recipe
  puts :name => recipe.name, :version => recipe.version
  recipe.cook
end
