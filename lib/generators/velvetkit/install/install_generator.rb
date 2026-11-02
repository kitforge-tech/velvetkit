# frozen_string_literal: true

require "rails/generators"
require "json"
require_relative "../helpers"

module Velvetkit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Helpers

      desc <<~DESC
        Set the app up for VelvetKit: choose the namespace, and add the base
        component, design tokens and translations every component uses, and
        choose the icon library the components draw from.

          bin/rails generate velvetkit:install --namespace=Kit --icons=phosphor
      DESC

      class_option :namespace, type: :string, default: Namespace::CANONICAL,
                               desc: "Module to put the components under"
      class_option :icons, type: :string, default: Icons::CANONICAL,
                           desc: "Icon library: #{Icons::LIBRARIES.keys.join(', ')}"
      class_option :skip_tests, type: :boolean, default: false, desc: "Don't copy the base component's test"
      class_option :skip_packages, type: :boolean, default: false,
                                   desc: "List the npm packages to add instead of installing them"
      class_option :skip_ai, type: :boolean, default: false,
                             desc: "Don't write docs/velvetkit.md and the pointers to it for AI agents"

      def write_config
        create_file CONFIG_FILE, <<~YAML
          # VelvetKit — https://velvetkit.com
          # `bin/rails generate velvetkit:add` puts components under this module,
          # with their icons from this library (#{Icons::LIBRARIES.keys.join(', ')}).
          namespace: #{kit_namespace.name}
          icons: #{icon_library}
        YAML
      end

      def add_gems
        gemfile = File.read(File.join(destination_root, "Gemfile"))
        gem "view_component" unless gemfile.match?(/gem ["']view_component["']/)
        gem "tailwind_merge" unless gemfile.match?(/gem ["']tailwind_merge["']/)
      end

      # Zeitwerk maps app/components/ui to Ui unless told UI is an acronym.
      def add_inflection
        return unless kit_namespace.acronym?

        inflections = "config/initializers/inflections.rb"
        rule = %(inflect.acronym "#{kit_namespace.name}")
        block = <<~RUBY
          ActiveSupport::Inflector.inflections(:en) do |inflect|
            #{rule}
          end
        RUBY
        return create_file(inflections, block) unless exists?(inflections)
        return if read(inflections).include?(rule)

        append_to_file inflections, "\n#{block}"
      end

      def copy_foundation
        Registry::FOUNDATION.each { |file| copy_from_registry(file) }
      end

      # tailwindcss-rails and cssbundling-rails keep the entry point in
      # different places; the tokens always live in app/assets/tailwind.
      TAILWIND_ENTRIES = {
        "app/assets/tailwind/application.css" => "./velvetkit.css",
        "app/assets/stylesheets/application.tailwind.css" => "../tailwind/velvetkit.css"
      }.freeze

      def import_stylesheet
        entry, path = TAILWIND_ENTRIES.find { |file, _| exists?(file) }
        return say_status(:css, "import velvetkit.css from your Tailwind entry point", :yellow) unless entry
        return if read(entry).include?("velvetkit.css")

        inject_into_file entry, %(@import "#{path}";\n), after: /@import ["']tailwindcss["'];?\n/
      end

      def add_base_component
        invoke "velvetkit:add", [ "base" ], namespace: kit_namespace.name, icons: icon_library, skip_tests: options[:skip_tests], skip_packages: true
      end

      def add_packages
        install_packages(Registry::FOUNDATION_PACKAGES)
      end

      def write_ai_reference
        invoke "velvetkit:ai", [], namespace: kit_namespace.name unless options[:skip_ai]
      end

      private

      def exists?(file)
        File.exist?(File.join(destination_root, file))
      end

      def read(file)
        File.read(File.join(destination_root, file))
      end
    end
  end
end
