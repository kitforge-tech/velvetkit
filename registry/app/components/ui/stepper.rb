# frozen_string_literal: true

# Where someone is in a multi-step form: the steps in order, each one done,
# current or still to come. `current:` is the 1-based number of the step
# they're on; steps before it are done, and `current: steps + 1` marks them
# all done. A step can override its own state with `status: :error`, for one
# that failed validation.
#
# Give a step an `href:` to let people go back to it; the current step is
# never a link. Screen readers hear each step's state, and the current one has
# aria-current="step". `orientation: :vertical` stacks the steps, with room for
# longer descriptions; horizontal hides descriptions on small screens.
class UI::Stepper < UI::Base
  renders_many :steps, ->(title:, **opts) { UI::Stepper::Step.new(title: title, **opts) }

  def initialize(current: 1, orientation: :horizontal, label: nil, class: nil, **html_attrs)
    @current     = current.to_i
    @orientation = orientation.to_sym
    @label       = label
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
  end

  attr_reader :current, :orientation

  def vertical? = @orientation == :vertical

  def list_classes
    cn(vertical? ? "flex flex-col" : "flex w-full items-start gap-2", @user_class)
  end

  def nav_attrs
    attrs = @html_attrs.except(:data, :aria)
    attrs[:data] = { slot: "stepper", orientation: @orientation }.merge(@html_attrs[:data] || {})
    attrs[:aria] = { label: @label || t("ui.stepper.label", default: "Progress") }.merge(@html_attrs[:aria] || {})
    attrs
  end
end
