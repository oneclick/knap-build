# encoding: UTF-8

module Knapsack
  class Recipe
    module Loader
      module Delegator
        def recipe(name, version, &block)
          recipe = Knapsack::Recipe.new(name, version, &block)
          Thread.current[:loaded_recipe] = recipe
        end
      end

      def self.load_from(filename)
        Kernel.load filename, true

        # retrieve loaded recipe from TLS
        recipe = Thread.current[:loaded_recipe]

        # location
        recipe.loaded_from = filename

        # cleanup
        Thread.current[:loaded_recipe] = nil

        recipe
      end
    end
  end
end

# extend main
extend Knapsack::Recipe::Loader::Delegator
