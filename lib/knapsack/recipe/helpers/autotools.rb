# encoding: UTF-8

module Knapsack
  class Recipe
    module Helpers
      module Autotools
        def define_autotools
          return if action?(:configure)

          sequence :configure, :compile, :install

          action :configure do
            args = ["sh", options.configure]

            # detect or add --host option for configure
            host_re = /--host/
            unless options.configure_args.find { |o| o =~ host_re }
              args << "--host=#{platform.target}"
            end

            args << "--prefix=#{install_path}"
            args.concat options.configure_args

            cmd = args.join(" ")
            run cmd
          end

          action :compile do
            args = options.make_args.join(" ")
            cmd = "make -f #{options.makefile} #{args}"
            run cmd
          end

          action :install do
            args = options.make_args.join(" ")
            cmd = "make install -f #{options.makefile} #{args}"
            run cmd
          end

          after :install do
            # only perform finish of libs if directory exists
            dir = install_path("lib")
            if File.directory?(dir)
              cmd = "sh libtool --finish #{dir}"
              run cmd
            end
          end
        end
      end
    end
  end
end
