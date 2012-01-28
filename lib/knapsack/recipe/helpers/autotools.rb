# encoding: UTF-8

module Knapsack
  class Recipe
    module Helpers
      module Autotools
        def define_autotools
          return if action?(:configure)

          sequence :configure, :compile, :install

          action :configure do
            args = options.configure_args.join(" ")
            cmd = "sh #{options.configure} #{args} --prefix=#{install_path}"
            run cmd, :verbose => options.verbose
          end

          action :compile do
            args = options.make_args.join(" ")
            cmd = "make -f #{options.makefile} #{args}"
            run cmd, :verbose => options.verbose
          end

          action :install do
            args = options.make_args.join(" ")
            cmd = "make install -f #{options.makefile} #{args}"
            run cmd, :verbose => options.verbose
          end

          after :install do
            cmd = "sh libtool --finish #{install_path('lib')}"
            run cmd, :verbose => options.verbose
          end
        end
      end
    end
  end
end
