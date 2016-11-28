module Knapsack
  class Recipe
    module Helpers
      module Patch
        def define_patch
          before :configure do
            # apply patches
            patches = Dir.glob(recipe_path("*.{diff,patch}")).sort

            relative_work_path = work_path.sub("#{Dir.pwd}/", "")
            patches.each do |patchfile|
              cmd = "git apply --ignore-space-change --ignore-whitespace --directory #{relative_work_path} #{patchfile}"
              run cmd, :nocd => true
            end
          end
        end
      end
    end
  end
end
