# frozen_string_literal: true

require "rails/generators"
require "json"
require_relative "../helpers"

module Velvetkit
  module Generators
    class AddGenerator < Rails::Generators::Base
      include Helpers

      desc <<~DESC
        Copy VelvetKit components into the app, with every component they use.

        Run with no components to list what is available.

          bin/rails generate velvetkit:add dialog date_picker
      DESC

      argument :components, type: :array, default: [], banner: "component component ..."

      class_option :namespace, type: :string,
                               desc: "Module for the components (default: #{CONFIG_FILE}, else UI)"
      class_option :all, type: :boolean, default: false, desc: "Add every component"
      class_option :skip_tests, type: :boolean, default: false, desc: "Don't copy component tests"
      class_option :skip_previews, type: :boolean, default: false, desc: "Don't copy Lookbook previews"
      class_option :skip_packages, type: :boolean, default: false,
                                   desc: "List the npm packages to add instead of installing them"

      def list_components
        return if requested.any?

        say "Usage: bin/rails generate velvetkit:add COMPONENT [COMPONENT ...]\n\n"
        registry.names.each { |name| say format("  %-16s %s", name, registry.description(name)) }
      end

      def copy_components
        resolved.each do |name|
          files = registry.component_files(name) + registry.javascript_files(name)
          files += registry.test_files(name) unless options[:skip_tests]
          files.uniq.each { |file| copy_from_registry(file) }
        end
      end

      def copy_previews
        return if options[:skip_previews]

        resolved.each do |name|
          needs = registry.preview_requires(name, resolved)
          if needs.any?
            say_status :skip, "#{name} preview, it also shows #{needs.join(', ')}", :yellow
          else
            registry.preview_files(name).each { |file| copy_from_registry(file) }
          end
        end
      end

      # Apps that list controllers in a manifest (jsbundling with
      # stimulus:manifest:update) need each one registered; apps that load the
      # directory (importmap, eagerLoadControllersFrom) need nothing.
      def register_stimulus_controllers
        manifest = File.join(destination_root, "app/javascript/controllers/index.js")
        return unless File.exist?(manifest) && !File.read(manifest).match?(/(eager|lazy)LoadControllersFrom/)

        controllers.each do |file|
          path = kit_namespace.rewrite_path(file).delete_prefix("app/javascript/controllers/").delete_suffix("_controller.ts")
          identifier = path.tr("_", "-").gsub("/", "--")
          next if File.read(manifest).match?(/["']#{Regexp.escape(identifier)}["']/)

          constant = "#{path.camelize.gsub('::', '__')}Controller"
          append_to_file "app/javascript/controllers/index.js", <<~JS
            \nimport #{constant} from "./#{path}_controller"
            application.register("#{identifier}", #{constant})
          JS
        end
      end

      def add_gems
        gemfile = File.read(File.join(destination_root, "Gemfile"))
        resolved.flat_map { |name| registry.gems(name).to_a }.uniq.each do |name, version|
          gem name, version unless gemfile.match?(/gem ["']#{name}["']/)
        end
      end

      def add_packages
        install_packages(resolved.flat_map { |name| registry.packages(name) }.uniq)
      end

      # Keep the agents' reference listing what is installed now.
      def refresh_ai_reference
        return if resolved.empty? || !File.exist?(File.join(destination_root, "docs/velvetkit.md"))

        invoke "velvetkit:ai", [], namespace: kit_namespace.name
      end

      private

      def resolved
        @resolved ||= requested.empty? ? [] : registry.resolve(requested)
      end

      def requested
        options[:all] ? registry.names : components
      end

      def controllers
        resolved.flat_map { |name| registry.stimulus_controllers(name) }.uniq
      end
    end
  end
end
