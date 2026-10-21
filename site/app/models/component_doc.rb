# One component's page in the docs: the gem's reference for it (examples,
# arguments, slots, notes, what `add` brings along), plus routing.
class ComponentDoc < Velvetkit::Reference
  def self.all
    names.map { |name| new(name) }
  end

  def self.find(name)
    raise ActionController::RoutingError, "No component #{name}" unless names.include?(name)

    new(name)
  end

  # base is plumbing every component inherits, not something to render.
  def self.names
    Velvetkit.registry.names - [ "base" ]
  end

  def to_param = name
end
