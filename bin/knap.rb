require "knapsack"

recipe_file = Dir.glob("var/**/*.knapfile").sort.first

recipe = Knapsack::RecipeLoader.load_from recipe_file

recipe.sequence.each do |a|
  recipe.perform(a)
end
