# encoding: UTF-8

require "digest/md5"
require "digest/sha2"
require "fileutils"
require "psych"

module Knapsack
  module Utils
    def download(url, filename)
      return true if File.exists?(filename)

      ensure_tree File.dirname(filename)

      cmd = ["curl", "-L", "-s", "-S", url, "-o", filename]

      pid = Process.spawn(*cmd, :err => [:child, :out], :out => IO::NULL)
      _, status = Process.wait2(pid)

      status.success?
    end
    module_function :download

    def extract(filename, target, options = {})
      ensure_tree target

      failure_message = "%s verification failed for #{File.basename(filename)} (expected: %s, was: %s)"

      if options.has_key?(:sha256)
        digest = Digest::SHA256.file(filename).hexdigest
        (digest == options[:sha256]) or
          raise failure_message % ["SHA256", options[:sha256], digest]
      end

      if options.has_key?(:md5)
        digest = Digest::MD5.file(filename).hexdigest
        (digest == options[:md5]) or
          raise failure_message % ["MD5", options[:md5], digest]
      end

      cmd = ["tar", "-xf", filename, "-C", target]

      pid = Process.spawn(*cmd, :err => [:child, :out], :out => IO::NULL)
      _, status = Process.wait2(pid)

      status.success? || options[:ignore_extract_errors]
    end
    module_function :extract

    def ensure_tree(target)
      FileUtils.mkdir_p target
    end
    module_function :ensure_tree

    def package(recipe)
      # name-version-platform.tar.lzma
      filename = "%s-%s-%s.tar.lzma" % [recipe.name, recipe.version, recipe.platform.simplified]
      pkg_name = Knapsack.packages_path(recipe.name, filename)

      ensure_tree File.dirname(pkg_name)

      unless File.exists?(pkg_name)
        path = recipe.install_path
        meta_file = File.join(path, ".metadata")
        entries_list = File.join(path, ".entries")

        metadata = {
          "package"      => {
            "name"     => recipe.name,
            "version"  => recipe.version.to_s,
            "platform" => recipe.platform.simplified
          },
          "dependencies" => [],
          "entries"      => []
        }

        # metadata.dependencies
        recipe.dep_list.each do |dep|
          metadata["dependencies"] << { dep.name => dep.requirement.to_s }
        end

        # metadata.entries
        entries = Dir.glob("#{path}/**/*").sort

        # remove directories
        entries.reject! { |e| File.directory?(e) }

        # remove recipe path and ensure proper encoding
        entries.map! { |e| e.gsub("#{path}/", "").encode(Encoding::UTF_8) }

        metadata["entries"] = entries

        # persist entries list
        File.open(entries_list, "w") do |f|
          f.puts entries
        end

        # persist metadata
        File.open(meta_file, "w") do |f|
          f.puts Psych.dump(metadata)
        end

        # tar --lzma
        puts "--> Building binary package #{filename}..."

        args = ["tar", "--lzma", "-cf"]
        args << pkg_name
        args << "-I" << entries_list
        args << "-C" << path

        args << File.basename(meta_file)

        cmd = args.join(" ")
        system cmd

        # Generate MD5
        File.open("#{pkg_name}.md5", "w") do |f|
          f.puts '%s *%s' % [Digest::MD5.file(pkg_name).hexdigest, filename]
        end

        # Generate SHA256
        File.open("#{pkg_name}.sha256", "w") do |f|
          f.puts "%s *%s" % [Digest::SHA256.file(pkg_name).hexdigest, filename]
        end

        puts "--> Done."
      end
    end
    module_function :package
  end
end
