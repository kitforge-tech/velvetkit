# The gem reads registry/components.yml once and keeps it, which is right in
# production. In development that hid every component added while the server
# ran: its page said "not found" until a restart. So the catalog is watched like
# the app's own code, and a change to it reloads the registry.
if Rails.env.development?
  Rails.application.config.watchable_files << File.join(Velvetkit.registry.root, "components.yml")
  Rails.application.reloader.to_prepare { Velvetkit.reload_registry! }
end
