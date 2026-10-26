# frozen_string_literal: true

require_relative "lib/velvetkit/version"

Gem::Specification.new do |spec|
  spec.name = "velvetkit"
  spec.version = Velvetkit::VERSION
  spec.authors = [ "Rain Root", "Rathan Kumar" ]
  spec.email = [ "rainroot.ghub@gmail.com", "rathan@kitforge.tech" ]

  spec.summary = "ViewComponent + Tailwind UI components, copied into your Rails app one at a time."
  spec.description = <<~DESC
    VelvetKit is a library of accessible ViewComponent UI components styled
    with Tailwind CSS 4 and wired up with Stimulus. Instead of loading the
    library at runtime, a generator copies just the components you ask for,
    and the ones they depend on, into your app under the namespace you choose.
  DESC
  spec.homepage = "https://velvetkit.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*", "registry/**/*", "README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.require_paths = [ "lib" ]

  # Generators only; the copied components need view_component and
  # tailwind_merge, which velvetkit:install adds to the app's Gemfile.
  spec.add_dependency "railties", ">= 7.1"
end
