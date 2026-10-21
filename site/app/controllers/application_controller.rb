class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  # The preview templates live in the registry; the Sidebar's share a partial
  # that they render by path, so the registry's previews are a view path too.
  append_view_path File.join(Velvetkit.registry.root, "test/components/previews")
end
