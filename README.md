# knap-build

Standarized recipe DSL to build and package software for Windows.

*The following is a copy of the original email sent to RubyInstaller group*

Hello,

As promised last week, was going to share something I've worked on my free
time.

# Background

To give a little bit of background, everybody knows Ruby depends on many
libraries to successfully compile.

RubyInstaller grew from the minimum dependencies that help Ruby and RubyGems
work to more dependencies for newer versions.

That is the case that now Ruby 1.9 recipe depends on 9 dependencies.

Most of those require to be compiled from source, since there is no official,
maintained or updated packages for Windows.

Over the past year, the need for a 64bits version of Ruby became more urgent.

For example, projects like Vagrant required special instructions for
Windows x64 since COM interfacing from 32bits process with VirtualBox was
not possible.

This also happens with other COM-based solutions and other support libraries.

It also became a constraint for those wanting to use Ruby to process a lot of
data and were limited in memory by 32bits design.

Last year there was an effort to bring 64bits into RubyInstaller, which
exposed a needed overhaul of RubyInstaller internals.

With that in mind, I took this time to analyze our current recipe structure,
needs and attempt to cover those into something more contained.

# Experiment

From that experimentation, I've created 'knap-build':

  http://packages.openknapsack.org/knap-build/knap-build-0.0.1.7z
  (md5: c5820f6dfa6e7dc92cc14777817db477)

The above package includes both knap-build tool and a series of recipes. Feel
free to extract it into any folder as long "bin" and "var" folders remain at
the same level.

Inside "bin" you will find a pre-compiled version of knap-build, which will
allow you compile the recipes provided inside "var/knapsack/recipes" folder.

## Requirements

In order to test-drive this tool, you will require:

* A working installation of RubyInstaller's DevKit (for compiling)
* curl command line utility (for download archives)
* Git (for applying patches)

These requirements needs to be in the PATH, so git, curl, gcc and make
commands are available. You can use devkitvars.bat to get DevKit into the
PATH.

## Building recipes

With all the above requirements in place, you can build any of the included
recipes, e.g.:

  bin\knap-build zlib

This will build latest version of the indicated recipe (at this time, 1.2.6)

You can use -h option to see other options, like building an specific version:

  bin\knap-build zlib --version 1.2.5

When building, you will see something like this as standard output:

  --> Detected platform: i686-pc-mingw32 (x86-windows)
  --> About to process zlib version 1.2.6 (x86-windows)
  --> Fetching files...
  --> Extracting files into work directory
  --> Configuring
  --> Compiling
  --> Staging
  --> Done.
  --> Activating zlib version 1.2.6 (x86-windows)...

Once a recipe has been build, subsequent calls to knap-build will only trigger
the activation process.

Even more, you can fire parallel compilation of recipes as long these do not
depend on each other.

## Recipe structure

Recipes are a group of actions that are executed in sequence by the builder.

This is a valid recipe:

  recipe "foo", "0.0.1" do
    sequence :first, :second, :third

    action :first do
      # ...
    end

    action :second do
      # ...
    end

    action :third do
      # ...
    end
  end

Which results in the following:

  --> Detected platform: i686-pc-mingw32 (x86-windows)
  --> About to process foo version 0.0.1 (x86-windows)
  --> Performing 'first'
  --> Performing 'second'
  --> Performing 'third'
  --> Done.
  --> Activating foo version 0.0.1 (x86-windows)...

Defining the same action twice will override previous definition.

Actions can also have 'before' and 'after' blocks which will be executed in
order.

Multiple blocks can be executed before or after, but only one can be executed
as action itself.

Included in the Recipe DSL exists helpers like 'use' and 'fetch', which their
only purpose is automate the definition of specific actions.

* Autotools (use :autotool)

Results in the definition of actions configure, compile and install that
follows autoconf/autotools behavior (configure, make, make install)

* Patch (use :patch)

It applies patches found in recipe_path to the extracted source code. This is
performed 'before' configure action.

* Fetch (fetch)

It defines files to be downloaded and extracted for this recipe. This
defines download and extract actions.

For example, take a look to zlib and openssl recipes. Both 'uses' autotools
actions, but they override some of the actions.

Others, like libiconv, use autotools defaults.

### Recipe dependency

Some recipes will require other libraries be activated first. Use 'depends_on'
to indicate such dependency and optionally provide a minimum version pattern:

  depends_on "zlib", ">= 1.2.5"

Dependencies will be activated (or build if required) prior building the
requested recipe.

### Platform conditionals and options

During the execution of actions, the platform that the recipe is targeting is
available using 'platform' helper:

  before :configure do
    if platform.posix?
      options.configure_args << "..."
    end
  end

Besides access to the platform when executing actions, you have access to
options that are used by your recipe.

The following is a list of defaults assumed for autotools:

  options.configure             = "configure"
  options.makefile              = "Makefile"
  options.configure_args        = []
  options.make_args             = []
  options.ignore_extract_errors = false
  options.verbose               = false

But you can define your own option and make that accessible later:

  before :configure do
    options.awesome = true
  end

  action :configure do
    if options.awesome
      # ...
    end
    # ...
  end

## Building 64bits software

That was the whole point of this, right? knap-build will detect from gcc what
platform GCC is targeting and use that to define the platform.

For example, using a custom RubyInstaller's DevKit (DKVER=tdm-64-4.6.1), you
can build zlib, openssl and all the included recipes:

  --> Detected platform: x86_64-w64-mingw32 (x64-windows)
  --> About to process zlib version 1.2.6 (x64-windows)
  --> Fetching files...
  --> Extracting files into work directory
  --> Configuring
  --> Compiling
  --> Staging
  --> Done.
  --> Activating zlib version 1.2.6 (x64-windows)...

The resulting 64bits library sits inside var/knapsack/software/x64-windows

## Packing binaries

As more experimental feature there is a --package switch that will generate
.tar.lzma packages of the compilation. It will bundle a file named .metadata
which describes the package (name, version and platform), dependencies and a
manifest of the files included in the package.

At a later phase, a complementary tool will be available to install and
activate those binary packages.

# Feedback

Feel free to download, extract, modify and experiment with the included
recipes or create your own. Please send your feedback to the list with your
thoughts.

Now, before leaving, the mandatory Why You did What, er, FAQ:

# FAQ

Q: Why knap-build is provided as executable and not in source code?

A: There are two reasons for that: first, avoid dependency on existing or
incompatible version of Ruby and second, code is an experiment, a research
and not production quality (yet).

Q: Why knap-build place compiled source in versioned folders instead of one
that I can add to my PATH?

A: The purpose of knap-build is build software in isolation, not provide an
common place where compiled software will live. The main goal of knap-build is
be used by package builders, not end-users.

Q: Can this work on Linux/OSX?

A: In theory, yes, I kept the recipes very platform-aware, but requires
testing.

Q: Why 'knap'

A: Knap is a stone used to build tools. I'm sturnborn and hard as a
stone/rock, so thought the name will fit.

Q: What is "knapsack"?, saw it in a bunch of directories.

A: LMGTFY: http://bit.ly/zpQqAT -- While I don't solve the problem, this tool
aim to help reduce the stress caused trying to figure out the right
dependencies.

Q: OK, got it, but openknapsack.org?

A: Future home for the OpenSource recipes and packages. More to come.

Q: OMG, you created yet-another-package/portage/build system!

A: OMG, Yes, I did it, sue me.
