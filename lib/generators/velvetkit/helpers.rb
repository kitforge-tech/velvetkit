# frozen_string_literal: true

require "velvetkit"

module Velvetkit
  module Generators
    # What the install and add generators share: where the registry is, which
    # namespace the app uses, and how a file gets from one to the other.
    module Helpers
      LOCKFILES = {
        "bun.lock" => "bun add",
        "bun.lockb" => "bun add",
        "yarn.lock" => "yarn add",
        "pnpm-lock.yaml" => "pnpm add",
        "package-lock.json" => "npm install"
      }.freeze

      ICONS_DIR = "app/assets/icons"

      private

      def registry
        Velvetkit.registry
      end

      # --namespace, else config/velvetkit.yml, else UI.
      def kit_namespace
        @kit_namespace ||= Namespace.new(options[:namespace] || configured_namespace || Namespace::CANONICAL)
      end

      def configured_namespace
        configured("namespace")
      end

      # --icons, else config/velvetkit.yml, else lucide.
      def icon_library
        @icon_library ||= Icons.library!(options[:icons] || configured("icons"))
      rescue Error => e
        raise Thor::Error, e.message
      end

      def configured(key)
        config = File.join(destination_root, CONFIG_FILE)
        YAML.load_file(config)&.fetch(key, nil) if File.exist?(config)
      end

      # Ruby and templates get the app's icon names, then its namespace.
      def copy_from_registry(file)
        source = registry.read(file)
        source = registry.icons.rewrite(source, icon_library) if file.end_with?(".rb", ".erb")
        create_file kit_namespace.rewrite_path(file), kit_namespace.rewrite(source)
      end

      # The SVG of every icon the files draw, in the app's library.
      def copy_icons(files)
        icons = registry.icons
        names = files.select { |file| file.end_with?(".rb", ".erb") }
                     .flat_map { |file| icons.names_in(registry.read(file)) }.uniq.sort
        names.select { |icon| icons.name(icon, icon_library) }.each do |icon|
          create_file File.join(ICONS_DIR, "#{icons.name(icon, icon_library)}.svg"),
                      registry.read(icons.svg_file(icon, icon_library))
        end
      end

      def install_packages(packages)
        package_json = File.join(destination_root, "package.json")
        missing = packages - installed_packages(package_json)
        return if missing.empty?

        specs = missing.map { |package| "#{package}@#{registry.package_version(package)}" }
        if options[:skip_packages] || !File.exist?(package_json)
          say_status :packages, "add these to package.json: #{specs.join(' ')}", :yellow
        else
          run "#{package_manager} #{specs.join(' ')}"
        end
      end

      def installed_packages(package_json)
        return [] unless File.exist?(package_json)

        json = JSON.parse(File.read(package_json))
        json.fetch("dependencies", {}).keys + json.fetch("devDependencies", {}).keys
      end

      def package_manager
        LOCKFILES.each { |lockfile, command| return command if File.exist?(File.join(destination_root, lockfile)) }
        "npm install"
      end
    end
  end
end
