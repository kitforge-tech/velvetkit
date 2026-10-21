# frozen_string_literal: true

require "yaml"
require "active_support/core_ext/string/inflections"

module Velvetkit
  # The components the gem can copy into an app, and everything each one needs.
  #
  # Paths are relative to the registry root and written against the canonical
  # `UI` namespace; Velvetkit::Namespace rewrites them on the way out.
  class Registry
    COMPONENTS = "app/components/ui"
    CONTROLLERS = "app/javascript/controllers/ui"
    TESTS = "test/components/ui"
    PREVIEWS = "test/components/previews/ui"

    # Installed by `velvetkit:install` rather than `velvetkit:add`.
    FOUNDATION = %w[
      config/locales/velvetkit.en.yml
      app/assets/tailwind/velvetkit.css
      app/javascript/velvetkit_icons.ts
    ].freeze
    FOUNDATION_PACKAGES = %w[@hotwired/stimulus lucide tw-animate-css].freeze

    attr_reader :root

    def initialize(root)
      @root = root
      @catalog = YAML.load_file(File.join(root, "components.yml"))
    end

    def names
      @catalog.fetch("components").keys
    end

    def description(name)
      fetch(name).fetch("description")
    end

    def package_version(package)
      @catalog.fetch("packages").fetch(package) do
        raise Error, "#{package} is imported but has no version in components.yml"
      end
    end

    # The requested components plus every component they render, base first.
    def resolve(requested)
      requested.each { |name| fetch(name) }

      resolved = []
      visiting = Set.new
      visit = lambda do |name|
        # A component already placed, or one whose dependencies are being
        # walked right now: two components may render each other.
        next if resolved.include?(name) || !visiting.add?(name)

        dependencies(name).each(&visit)
        resolved << name
      end
      ([ "base" ] + requested).each(&visit)
      resolved
    end

    def dependencies(name)
      sources = component_files(name) + test_files(name)
      (references(sources) - [ name ]).sort
    end

    # Ruby, templates and any extra files listed in the catalog.
    def component_files(name)
      files = glob("#{COMPONENTS}/#{name}.*", "#{COMPONENTS}/#{name}/**/*")
      files + fetch(name).fetch("files", [])
    end

    def test_files(name)
      glob("#{TESTS}/#{name}_test.rb", "#{TESTS}/#{name}/**/*")
    end

    def preview_files(name)
      glob("#{PREVIEWS}/#{name}_preview.rb", "#{PREVIEWS}/#{name}_preview/**/*")
    end

    # Components a preview renders that are not in `installed`. A preview with
    # any is skipped rather than shipped broken.
    def preview_requires(name, installed)
      references(preview_files(name)) - installed - [ name ]
    end

    # Stimulus controllers, their shared helpers and lazily-loaded entry points.
    def javascript_files(name)
      sources = component_files(name)
      controllers = scan(sources, /\bui--([a-z]+(?:-[a-z]+)*)/).filter_map { |id| controller_for(id) }
      entry_points = scan(sources, /asset_path\(["']([a-z_]+)\.js["']\)/).map { |entry| "app/javascript/#{entry}.ts" }
      js = (controllers + entry_points).uniq
      internals = scan(js, %r{from ['"]\./_internal/([a-z_]+)\.js['"]}).map { |f| "#{CONTROLLERS}/_internal/#{f}.ts" }
      js + internals.uniq
    end

    def stimulus_controllers(name)
      javascript_files(name).select { |f| f.start_with?(CONTROLLERS) && f.end_with?("_controller.ts") }
    end

    def packages(name)
      scan(javascript_files(name), /(?:from|import)\s+['"]([^.'"][^'"]*)['"]/)
        .map { |spec| spec.start_with?("@") ? spec.split("/").first(2).join("/") : spec.split("/").first }
        .uniq.sort
    end

    # Gems the component needs, with the version to add to the Gemfile.
    def gems(name)
      fetch(name).fetch("gems", []).to_h { |gem| [ gem, @catalog.fetch("gems").fetch(gem) ] }
    end

    def read(file)
      File.read(File.join(root, file))
    end

    private

    def fetch(name)
      @catalog.fetch("components").fetch(name.to_s) do
        raise Error, "Unknown component #{name.inspect}. Available: #{names.join(', ')}"
      end
    end

    # Components the files render. Comments don't count: a component's notes
    # may point at another without needing it.
    def references(files)
      files.flat_map { |file| code(file).scan(/\bUI::([A-Z][A-Za-z0-9]*)/).flatten }
           .map(&:underscore).select { |n| names.include?(n) }.uniq
    end

    def code(file)
      read(file).gsub(/^\s*#.*$/, "").gsub(/<%#.*?%>/m, "")
    end

    # `ui--data-grid-url-value` names the data-grid controller; drop trailing
    # words until what is left matches a controller file.
    def controller_for(attribute)
      words = attribute.split("-")
      words.size.downto(1) do |n|
        file = "#{CONTROLLERS}/#{words.first(n).join('_')}_controller.ts"
        return file if exist?(file)
      end
      nil
    end

    def scan(files, pattern)
      files.flat_map { |file| read(file).scan(pattern).flatten }.uniq
    end

    def glob(*patterns)
      patterns.flat_map { |pattern| Dir.glob(pattern, base: root) }
              .select { |f| File.file?(File.join(root, f)) }
              .sort
    end

    def exist?(file)
      File.exist?(File.join(root, file))
    end
  end
end
