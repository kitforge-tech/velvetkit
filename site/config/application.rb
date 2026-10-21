require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
# require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Site
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Component pages render the registry's preview templates, and some of
    # those read constants from their preview class (UI::SelectPreview::SECTIONS).
    previews = File.join(Velvetkit.registry.root, "test/components/previews")
    config.autoload_paths << previews

    # The same previews, browsable in Lookbook at /lookbook, in production too.
    config.view_component.previews.paths = [ previews ]
    config.view_component.previews.enabled = true
    config.view_component.previews.default_layout = "component_preview"
    config.lookbook.preview_paths = [ previews ]
    config.lookbook.preview_layout = "component_preview"
    config.lookbook.project_name = "VelvetKit"
    # Lookbook has no purple theme, so retint indigo with a velvet scale.
    config.lookbook.ui_theme = "indigo"
    config.lookbook.ui_theme_overrides = {
      accent_50: "oklch(0.97 0.02 301.6)",
      accent_100: "oklch(0.94 0.04 301.6)",
      accent_200: "oklch(0.88 0.08 301.6)",
      accent_300: "oklch(0.8 0.12 301.6)",
      accent_400: "oklch(0.68 0.16 301.6)",
      accent_500: "oklch(0.55 0.17 301.6)",
      accent_600: "oklch(0.45 0.17 301.6)",
      accent_700: "oklch(0.357 0.158 301.6)",
      accent_800: "oklch(0.3 0.13 301.6)",
      accent_900: "oklch(0.25 0.1 301.6)",
      favicon_light_mode: "#4D1A7F",
      favicon_dark_mode: "#B580F4"
    }
    # Live updates need ActionCable, which this site doesn't run.
    config.lookbook.live_updates = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
