module Knapsack
  class Recipe
    module Helpers
      module Patch
        def define_patch
          before :configure do
            # apply patches
            patches = Dir.glob(recipe_path("*.{diff,patch}")).sort

            patches.each do |patchfile|
              run "git apply --directory #{work_path} #{patchfile}", :nocd => true
            end
          end
        end
      end
    end
  end
end
