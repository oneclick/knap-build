# encoding: UTF-8

require "digest/md5"
require "fileutils"

module Knapsack
  module Utils
    def download(url, filename)
      return true if File.exists?(filename)

      ensure_tree File.dirname(filename)

      cmd = ["curl", "-s", "-S", url, "-o", filename]

      pid = Process.spawn(*cmd, :err => [:child, :out], :out => IO::NULL)
      _, status = Process.wait2(pid)

      status.success?
    end
    module_function :download

    def extract(filename, md5, target, options = {})
      ensure_tree target

      # verify checksum first
      computed_md5 = Digest::MD5.file(filename).hexdigest
      unless computed_md5 == md5
        raise "MD5 verification failed for #{File.basename(filename)} (expected: #{md5}, was: #{computed_md5}"
      end

      cmd = ["tar", "xf", filename, "-C", target]

      pid = Process.spawn(*cmd, :err => [:child, :out], :out => IO::NULL)
      _, status = Process.wait2(pid)

      status.success? || options[:ignore_extract_errors]
    end
    module_function :extract

    def ensure_tree(target)
      FileUtils.mkdir_p target
    end
    module_function :ensure_tree
  end
end
