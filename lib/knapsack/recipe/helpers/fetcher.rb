module Knapsack
  class Recipe
    module Helpers
      module Fetcher
        def fetch(url, options = {})
          @files ||= {}

          filename = File.basename(url)

          @files[filename] ||= options.merge(:url => url)

          define_fetcher
        end

        def define_fetcher
          return if action?(:download) && action?(:extract)

          action :download do
            @files.each do |filename, opt|
              Knapsack::Utils.download opt[:url], distfiles_path(filename)
            end
          end

          action :extract do
            @files.each do |filename, opt|
              Knapsack::Utils.extract distfiles_path(filename),
                opt[:md5], extract_path,
                :ignore_extract_errors => options.ignore_extract_errors
            end
          end

          prepend_sequence :download, :extract
        end
      end
    end
  end
end
