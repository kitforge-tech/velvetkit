# frozen_string_literal: true

require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "view_component"
require "tailwind_merge"
require "pagy"
require "velvetkit"

# The smallest Rails app the components render in. It loads them from the
# registry, or from wherever VELVETKIT_APP_ROOT points — rake test:namespaced
# uses that to test a copy made by the add generator.
module Dummy
  APP_ROOT = ENV.fetch("VELVETKIT_APP_ROOT") { File.expand_path("../../../registry", __dir__) }
  NAMESPACE = Velvetkit::Namespace.new(ENV.fetch("VELVETKIT_NAMESPACE", "UI"))

  class Application < Rails::Application
    config.load_defaults 8.1
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.logger = Logger.new(nil)
    config.secret_key_base = "velvetkit-dummy"
    config.autoload_paths << File.join(APP_ROOT, "app/components")
    config.i18n.load_path += Dir[File.join(APP_ROOT, "config/locales/*.yml")]
  end
end

if Dummy::NAMESPACE.acronym?
  ActiveSupport::Inflector.inflections(:en) { |inflect| inflect.acronym Dummy::NAMESPACE.name }
end
