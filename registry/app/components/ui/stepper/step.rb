# frozen_string_literal: true

# One step in a UI::Stepper. Its state comes from the stepper's `current:`
# unless `status:` (:complete, :current, :upcoming or :error) sets it.
class UI::Stepper::Step < UI::Base
  STATUSES = %i[complete current upcoming error].freeze

  INDICATOR = {
    complete: "bg-primary text-primary-foreground border-primary",
    current:  "border-2 border-primary text-primary bg-background",
    upcoming: "border-border text-muted-foreground bg-background",
    error:    "border-2 border-destructive text-destructive bg-background"
  }.freeze

  ICONS = { complete: "check", error: "circle-alert" }.freeze

  def initialize(title:, description: nil, href: nil, status: nil, class: nil, **html_attrs)
    @title       = title
    @description = description
    @href        = href
    @status      = status&.to_sym
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
  end

  attr_reader :number

  def place(stepper, number, last:)
    @stepper = stepper
    @number  = number
    @last    = last
  end

  def status
    return @status if STATUSES.include?(@status)

    if @number < @stepper.current then :complete
    elsif @number == @stepper.current then :current
    else :upcoming
    end
  end

  def last? = @last
  def vertical? = @stepper.vertical?
  def link? = @href.present? && status != :current
  def icon_name = ICONS[status]

  def item_attrs
    attrs = @html_attrs.except(:data)
    attrs[:class] = cn(
      vertical? ? "relative flex gap-3 pb-8 last:pb-0" : "flex min-w-0 items-center gap-2",
      { "flex-1" => !vertical? && !last?, "max-sm:flex-auto" => !vertical? && !last? && titled? },
      @user_class
    )
    attrs[:aria] = { current: ("step" if status == :current) }.compact.merge(@html_attrs[:aria] || {})
    attrs[:data] = { slot: "stepper-step", status: status }.merge(@html_attrs[:data] || {})
    attrs
  end

  def indicator_classes
    cn("relative z-10 flex size-8 shrink-0 items-center justify-center rounded-full border text-sm font-medium",
       INDICATOR[status])
  end

  def title_classes
    cn("text-sm font-medium",
       status == :upcoming ? "text-muted-foreground" : "text-foreground",
       { "text-destructive" => status == :error, "underline-offset-4 group-hover/step:underline" => link? })
  end

  # A horizontal stepper on a phone has room for the indicators and a title or
  # two, so it shows the current step's (and any with an error) at full width
  # and keeps the rest for screen readers only.
  def description_classes
    cn("text-sm text-muted-foreground", { "max-sm:sr-only" => !vertical? })
  end

  def text_classes
    return "flex min-w-0 flex-col gap-0.5 pt-1.5" if vertical?

    cn("flex min-w-0 flex-col", { "max-sm:sr-only" => !titled? })
  end

  def body_classes
    cn("flex min-w-0", vertical? ? "gap-3" : "items-center gap-2", { "max-sm:shrink-0" => !vertical? && titled? })
  end

  def titled? = %i[current error].include?(status)

  def link_classes
    cn(body_classes, "group/step rounded-md outline-none focus-visible:ring-[3px] focus-visible:ring-ring/40")
  end

  # Horizontal: a line after the step that fills the space to the next one.
  # Vertical: a line down from the indicator to the next step.
  def connector_classes
    done = status == :complete
    if vertical?
      cn("absolute left-4 top-10 bottom-2 w-px -translate-x-1/2", done ? "bg-primary" : "bg-border")
    else
      cn("h-px min-w-4 flex-1", done ? "bg-primary" : "bg-border")
    end
  end

  def status_text
    t("ui.stepper.#{status}", default: { complete: "Completed", current: "Current step",
                                         upcoming: "Not started", error: "Needs attention" }[status])
  end
end
