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
              name = opt.fetch(:as, filename)

              Knapsack::Utils.download opt[:url], distfiles_path(name)
            end
          end

          action :extract do
            @files.each do |filename, opt|
              name = opt.fetch(:as, filename)

              combined = {
                :ignore_extract_errors => options.ignore_extract_errors
              }

              opt.has_key?(:sha256) and
                combined.update(:sha256 => opt[:sha256])

              opt.has_key?(:md5) and
                combined.update(:md5 => opt[:md5])

              Knapsack::Utils.extract(distfiles_path(name), extract_path,
                                        combined)
            end
          end

          prepend_sequence :download, :extract
        end
      end
    end
  end
end
