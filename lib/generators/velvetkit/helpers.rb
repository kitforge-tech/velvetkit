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

      private

      def registry
        Velvetkit.registry
      end

      # --namespace, else config/velvetkit.yml, else UI.
      def kit_namespace
        @kit_namespace ||= Namespace.new(options[:namespace] || configured_namespace || Namespace::CANONICAL)
      end

      def configured_namespace
        config = File.join(destination_root, CONFIG_FILE)
        YAML.load_file(config)&.fetch("namespace", nil) if File.exist?(config)
      end

      def copy_from_registry(file)
        create_file kit_namespace.rewrite_path(file), kit_namespace.rewrite(registry.read(file))
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
