# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

# The gem itself: namespace rewriting, the registry, the generators.
Rake::TestTask.new("test:gem") do |t|
  t.libs << "test"
  t.test_files = FileList["test/velvetkit/**/*_test.rb"]
end

# The components, straight from the registry under the canonical UI namespace.
Rake::TestTask.new("test:components") do |t|
  t.libs << "test"
  t.test_files = FileList["registry/test/components/**/*_test.rb"]
end

# Every component copied out under a different namespace by the add
# generator, then tested from the copy. Proves the rewrite leaves nothing
# pointing at UI.
desc "Generate all components as Kit:: into tmp/ and run their tests"
task "test:namespaced" do
  out = File.expand_path("tmp/namespaced", __dir__)
  rm_rf out
  ruby "test/support/generate_all.rb", out, "Kit"
  tests = FileList["#{out}/test/components/**/*_test.rb"]
  sh({ "VELVETKIT_APP_ROOT" => out, "VELVETKIT_NAMESPACE" => "Kit" },
     "ruby", "-Itest", "-e", "ARGV.each { |f| require f }", *tests)
end

task test: %w[test:gem test:components test:namespaced]
task default: :test
