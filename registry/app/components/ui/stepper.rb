# frozen_string_literal: true

require "securerandom"

# The steps of a multi-step flow, each one done, current, still to come, or in
# trouble. `current:` is the 1-based number of the step someone is on: steps
# before it are done, and `current: steps + 1` marks them all done. A step can
# set its own state with `status:` (:complete, :current, :upcoming, :error or
# :loading), for one that failed or is still being checked.
#
# Looks: `variant: :default` draws numbered circles and `:dot` small dots.
# Horizontal steppers put each title under its step, `align: :start` (at the
# left of it) or `:center`; `orientation: :vertical` puts it beside, with room
# for a description and more. `connector: false` drops the lines, and
# `labels: false` keeps the titles for screen readers only. Where it has less
# than 28rem (a phone, a narrow card), a horizontal stepper shows just its
# steps, with "Step 2 of 4" and the current title under them.
#
# A step's block is its panel: what someone fills in on that step. Give the
# steps panels and the stepper moves between them in the browser; a button
# with `data-action="ui--stepper#next"` checks the panel's fields and moves
# on, marking the step as an error if one is invalid, and `ui--stepper#previous`
# goes back. Give a button `data-ui--stepper-target="next"` or `"previous"` and
# it hides when there's nowhere to go, and `"submit"` shows only on the last
# step. Panels sit under the steps; `layout: :side` puts a vertical stepper
# beside them, given the room, and `layout: :inline` puts each one under its
# step's title. The stepper's own block comes after the panels, for those
# buttons; `with_completion` is shown once every step is done.
#
# To validate on the server instead, render the stepper with the step the
# server says someone is on and post each panel's form. While a form inside
# the stepper is submitting, its current step shows a spinner.
#
# Give a done step an `href:` to let people go back to it. Screen readers hear
# each step's state, and the current one has aria-current="step".
class UI::Stepper < UI::Base
  ORIENTATIONS = %i[horizontal vertical].freeze

  # The step's block is captured here, as its panel, rather than as the step's
  # content: the stepper puts it after the list, apart from the step.
  renders_many :steps, ->(title:, **opts, &block) {
    UI::Stepper::Step.new(title: title, **opts).tap { |step| step.panel = block&.call }
  }
  renders_one :completion

  def initialize(current: 1, orientation: :horizontal, variant: :default, align: :start, layout: :stacked,
                 connector: true, labels: true, label: nil, class: nil, **html_attrs)
    @current     = current.to_i
    @orientation = ORIENTATIONS.include?(orientation.to_sym) ? orientation.to_sym : :horizontal
    @variant     = variant.to_sym == :dot ? :dot : :default
    @align       = align.to_sym == :center ? :center : :start
    @layout      = layout.to_sym
    @connector   = connector
    @labels      = labels
    @label       = label
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
  end

  attr_reader :current, :orientation, :variant, :align

  def vertical? = @orientation == :vertical
  def dot? = @variant == :dot
  def connector? = @connector
  def labels? = @labels
  def side? = vertical? && @layout == :side
  def inline? = vertical? && @layout == :inline
  def finished? = @current > steps.size

  def id = @html_attrs[:id] || (@id ||= "ui-stepper-#{SecureRandom.hex(4)}")

  def before_render
    steps.each_with_index { |step, index| step.place(self, index + 1, last: index == steps.size - 1) }
  end

  # Panels that sit apart from the list: every layout but :inline, which puts
  # each one inside its step.
  def panels = inline? ? [] : steps.select(&:panel?)
  def body? = panels.any? || completion? || content.present?

  def root_attrs
    attrs = @html_attrs.except(:data, :aria, :id)
    attrs[:id] = id
    attrs[:class] = cn("group/stepper @container/stepper w-full", @user_class)
    attrs[:data] = {
      slot: "stepper", orientation: @orientation, variant: @variant,
      controller: "ui--stepper",
      "ui--stepper-current-value": @current,
      "ui--stepper-summary-value": t("ui.stepper.summary", default: "Step %{current} of %{total}"),
      action: "keydown->ui--stepper#keydown input->ui--stepper#revalidate change->ui--stepper#revalidate " \
              "turbo:submit-start->ui--stepper#submitting turbo:submit-end->ui--stepper#submitted"
    }.merge(@html_attrs[:data] || {})
    attrs
  end

  def nav_attrs
    { aria: { label: @label || t("ui.stepper.label", default: "Progress") }.merge(@html_attrs[:aria] || {}),
      class: cn("min-w-0", { "@md/stepper:sticky @md/stepper:top-6 @md/stepper:self-start" => side? }) }
  end

  # Side by side once the stepper has the room, measured on itself rather
  # than the window, so it works in a card or a docs column too.
  def frame_classes
    side? ? "grid gap-8 @md/stepper:grid-cols-[minmax(10rem,14rem)_1fr] @md/stepper:gap-10" : "contents"
  end

  def list_classes
    vertical? ? "flex flex-col" : "flex w-full items-start"
  end

  def body_classes
    cn("min-w-0", { "mt-8" => !side? && !inline? })
  end

  def panel_attrs(step)
    { id: "#{id}-panel-#{step.number}", hidden: step.number != @current, tabindex: -1, role: "group",
      aria: { labelledby: step.title_id },
      data: { "ui--stepper-target": "panel", step: step.number },
      class: UI::Stepper::Step::PANEL_CLASSES }
  end

  def completion_attrs
    { hidden: !finished?, tabindex: -1, data: { "ui--stepper-target": "completion" },
      class: UI::Stepper::Step::PANEL_CLASSES }
  end

  # "Step 2 of 4" and the current title, under a horizontal stepper on a phone,
  # where the titles don't fit. Screen readers get each step's own text instead.
  def summary?
    !vertical? && steps.size > 1
  end

  def summary_text
    shown = @current.clamp(1, steps.size)
    format = t("ui.stepper.summary", default: "Step %{current} of %{total}")
    "#{format.sub('%{current}', shown.to_s).sub('%{total}', steps.size.to_s)}: #{steps[shown - 1].title}"
  end
end
