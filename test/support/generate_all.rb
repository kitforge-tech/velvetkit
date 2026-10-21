# frozen_string_literal: true

# Copies every component into DESTINATION under NAMESPACE, the way an app
# would get them from `bin/rails generate velvetkit:add`.
#
#   ruby test/support/generate_all.rb tmp/namespaced Kit
$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "fileutils"
require "generators/velvetkit/add/add_generator"
require "generators/velvetkit/install/install_generator"

destination, namespace = ARGV
FileUtils.mkdir_p(destination)
File.write(File.join(destination, "Gemfile"), "")

Velvetkit::Generators::InstallGenerator.start(
  [ "--namespace=#{namespace}", "--skip-packages", "--quiet" ], destination_root: destination
)
Velvetkit::Generators::AddGenerator.start(
  Velvetkit.registry.names + [ "--skip-packages", "--quiet" ], destination_root: destination
)
