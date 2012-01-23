module Knapsack
  class Recipe
    module Helpers
      module Autotools
        def define_autotools
          return if action?(:configure)

          sequence :configure, :compile, :install

          action :configure do
            run "sh #{options.configure} --prefix=#{install_path}"
          end

          action :compile do
            run "make -f #{options.makefile}"
          end

          action :install do
            run "make install -f #{options.makefile}"
          end
        end
      end
    end
  end
end
