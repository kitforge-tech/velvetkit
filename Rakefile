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

# Every component copied out under a different namespace and icon library by
# the add generator, then tested from the copy. Proves the rewrite leaves
# nothing pointing at UI, and every icon renamed and its SVG copied.
desc "Generate all components as Kit:: with Phosphor icons into tmp/ and run their tests"
task "test:namespaced" do
  out = File.expand_path("tmp/namespaced", __dir__)
  rm_rf out
  ruby "test/support/generate_all.rb", out, "Kit", "phosphor"
  tests = FileList["#{out}/test/components/**/*_test.rb"]
  sh({ "VELVETKIT_APP_ROOT" => out, "VELVETKIT_NAMESPACE" => "Kit" },
     "ruby", "-Itest", "-e", "ARGV.each { |f| require f }", *tests)
end

desc "Download the SVG of every icon in registry/icons.yml, for each library"
task "icons:sync" do
  require_relative "lib/velvetkit"
  icons = Velvetkit.registry.icons
  failed = []
  Velvetkit::Icons::LIBRARIES.each_key do |library|
    dir = File.join(icons.root, "icons", library)
    mkdir_p dir, verbose: false
    wanted = icons.canonical.map { |icon| icons.svg_file(icon, library) }.uniq
    wanted.each do |file|
      path = File.join(icons.root, file)
      next if File.exist?(path)

      File.write(path, Velvetkit::Icons.download(File.basename(file, ".svg"), library))
      puts "  fetched #{file}"
    rescue Velvetkit::Error => e
      failed << e.message
    end
    stale = Dir[File.join(dir, "*.svg")] - wanted.map { |file| File.join(icons.root, file) }
    rm stale, verbose: true if stale.any?
  end
  abort failed.join("\n") if failed.any?
end

task test: %w[test:gem test:components test:namespaced]
task default: :test
