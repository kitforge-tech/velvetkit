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

  # Listed under Forms in the sidebar, after the forms guide, in this order.
  FORMS = %w[form_field input textarea select native_select checkbox switch radio_group
             date_picker password_input input_group label].freeze

  def self.forms = FORMS.map { |name| new(name) }

  def form? = FORMS.include?(name)

  def to_param = name

  # The component as one Markdown page, for agents: named as VelvetKit's so
  # an AI knows which library it belongs to. Served as .md and copied by
  # "Copy as Markdown".
  def page_markdown = "# VelvetKit\n\n#{to_markdown}"
end
