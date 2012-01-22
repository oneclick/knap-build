require "fileutils"

module Knapsack
  module Utils
    def download(url, target)
      return true if File.exists?(target)

      ensure_tree target

      cmd = ["curl", "-s", "-S", url, "-o", target]

      pid = Process.spawn(*cmd, :err => :out, :out => IO::NULL)
      _, status = Process.wait2(pid)

      status.success?
    end
    module_function :download

    def extract(filename, md5, target)
    end
    module_function :extract

    def ensure_tree(filename)
      dirname = File.dirname(filename)
      FileUtils.mkdir_p dirname
    end
    module_function :ensure_tree
  end
end
