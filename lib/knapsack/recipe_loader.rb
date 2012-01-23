module Knapsack
  module RecipeLoader
    module Delegator
      def recipe(name, version, &block)
        r = Knapsack::Recipe.new(name, version, &block)
        r.source_file = block.source_location.first
        Thread.current[:loaded_recipe] = r
      end
    end

    def self.load_from(filename)
      Kernel.load filename, true

      # retrieve loaded recipe from TLS
      recipe = Thread.current[:loaded_recipe]

      # cleanup
      Thread.current[:loaded_recipe] = nil

      recipe
    end
  end
end

# extend main
extend Knapsack::RecipeLoader::Delegator
