# frozen_string_literal: true

require "rails/generators"
require_relative "../helpers"

module Velvetkit
  module Generators
    # Puts icon SVGs in app/assets/icons, where the Icon component reads them.
    #
    # Names are the app's icon library's own (config/velvetkit.yml). An icon
    # the kit already ships is copied from the gem; any other is downloaded
    # from the npm CDN, pinned to the version the kit was built against.
    class IconsGenerator < Rails::Generators::Base
      include Helpers

      SOURCES = "app/{components,views,helpers}/**/*.{rb,erb}"

      desc <<~DESC
        Add icons to app/assets/icons, from the library in #{CONFIG_FILE}.

        Name them, or run with none to add every icon the app's own
        components, views and helpers draw that has no SVG yet.

          bin/rails generate velvetkit:icons rocket user
          bin/rails generate velvetkit:icons
      DESC

      argument :names, type: :array, default: [], banner: "icon icon ..."

      class_option :icons, type: :string,
                           desc: "Icon library: #{Icons::LIBRARIES.keys.join(', ')} (default: #{CONFIG_FILE}, else lucide)"

      def add_icons
        wanted = names.any? ? names : (drawn - present)
        return say_status(:icons, "every icon drawn has an SVG in #{ICONS_DIR}", :green) if wanted.empty?

        failed = wanted.uniq.reject { |name| add(name) }
        return if failed.empty?

        say_status :error, "no SVG for #{failed.join(', ')}. Browse #{icon_library}'s icons at " \
                           "#{Icons::LIBRARIES.dig(icon_library, :browse)}", :red
      end

      private

      def add(name)
        create_file File.join(ICONS_DIR, "#{name}.svg"), shipped(name) || Icons.download(name, icon_library)
        true
      rescue Velvetkit::Error => e
        say_status :missing, e.message, :yellow
        false
      end

      # The gem's copy, when the kit draws this icon itself.
      def shipped(name)
        file = File.join(registry.root, "icons", icon_library, "#{name}.svg")
        File.read(file) if name.match?(/\A#{Icons::NAME}\z/o) && File.file?(file)
      end

      def drawn
        Dir.glob(SOURCES, base: destination_root).flat_map do |file|
          registry.icons.names_in(File.read(File.join(destination_root, file)))
        end.uniq.sort
      end

      def present
        Dir.glob("*.svg", base: File.join(destination_root, ICONS_DIR)).map { |file| file.delete_suffix(".svg") }
      end
    end
  end
end
