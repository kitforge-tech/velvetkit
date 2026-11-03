# frozen_string_literal: true

# One step in a UI::Stepper: its indicator, its title and description, and the
# line on to the next step. Its state comes from the stepper's `current:`
# unless `status:` sets it. `icon:` draws an icon in place of the number.
#
# Every state's look hangs off the step's data-status, so the stepper's
# controller only has to change that attribute to move someone along.
class UI::Stepper::Step < UI::Base
  STATUSES = %i[complete current upcoming error loading].freeze

  # Shown when a panel appears, after the first move, so a page load is still.
  PANEL_CLASSES = "outline-none group-data-[moved]/stepper:animate-in group-data-[moved]/stepper:fade-in " \
                  "group-data-[moved]/stepper:duration-300 group-data-[moved]/stepper:slide-in-from-right-4 " \
                  "group-data-[direction=back]/stepper:slide-in-from-left-4 motion-reduce:animate-none"

  # Written out in full, state by state, so Tailwind finds every class. Current
  # and loading look alike: a ring round the step someone is on.
  INDICATOR = {
    default: "size-8 border text-sm font-medium border-transparent bg-muted text-muted-foreground " \
             "group-data-[status=complete]/step:border-primary group-data-[status=complete]/step:bg-primary " \
             "group-data-[status=complete]/step:text-primary-foreground " \
             "group-data-[status=current]/step:border-2 group-data-[status=current]/step:border-primary " \
             "group-data-[status=current]/step:bg-transparent group-data-[status=current]/step:text-primary " \
             "group-data-[status=current]/step:ring-4 group-data-[status=current]/step:ring-primary/15 " \
             "group-data-[status=loading]/step:border-2 group-data-[status=loading]/step:border-primary " \
             "group-data-[status=loading]/step:bg-transparent group-data-[status=loading]/step:text-primary " \
             "group-data-[status=loading]/step:ring-4 group-data-[status=loading]/step:ring-primary/15 " \
             "group-data-[status=error]/step:border-destructive group-data-[status=error]/step:bg-destructive " \
             "group-data-[status=error]/step:text-white group-data-[status=error]/step:ring-4 " \
             "group-data-[status=error]/step:ring-destructive/15",
    dot: "size-3 bg-muted-foreground/30 group-data-[status=complete]/step:bg-primary " \
         "group-data-[status=current]/step:border-2 group-data-[status=current]/step:border-primary " \
         "group-data-[status=current]/step:bg-transparent group-data-[status=current]/step:ring-4 " \
         "group-data-[status=current]/step:ring-primary/15 " \
         "group-data-[status=loading]/step:border-2 group-data-[status=loading]/step:border-primary " \
         "group-data-[status=loading]/step:bg-transparent group-data-[status=loading]/step:ring-4 " \
         "group-data-[status=loading]/step:ring-primary/15 group-data-[status=loading]/step:animate-pulse " \
         "group-data-[status=error]/step:bg-destructive group-data-[status=error]/step:ring-4 " \
         "group-data-[status=error]/step:ring-destructive/15"
  }.freeze

  # Each glyph shows in its own state only; the swap animates after a move.
  GLYPH = "group-data-[moved]/stepper:animate-in group-data-[moved]/stepper:zoom-in-50 " \
          "group-data-[moved]/stepper:fade-in group-data-[moved]/stepper:duration-300 motion-reduce:animate-none"

  attr_reader :number, :title
  attr_accessor :panel

  def initialize(title:, description: nil, href: nil, status: nil, icon: nil, class: nil, **html_attrs)
    @title       = title
    @description = description
    @href        = href
    @status      = status&.to_sym
    @icon        = icon
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
  end

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

  def panel? = panel.present?
  def last? = @last
  def vertical? = @stepper.vertical?
  def dot? = @stepper.dot?
  def center? = !vertical? && @stepper.align == :center
  def link? = @href.present? && %i[complete error].include?(status)
  def title_id = "#{@stepper.id}-step-#{@number}"
  def description? = @description.present?
  def inline_panel? = @stepper.inline? && panel?
  def number_glyph = @icon ? render(UI::Icon.new(name: @icon, size: :sm)) : @number.to_s

  def item_attrs
    attrs = @html_attrs.except(:data, :aria)
    attrs[:class] = cn("group/step relative min-w-0", item_layout, @user_class)
    attrs[:aria] = { current: ("step" if %i[current loading].include?(status)) }.compact.merge(@html_attrs[:aria] || {})
    attrs[:data] = { slot: "stepper-step", status: status, "ui--stepper-target": "step" }
                   .merge(@html_attrs[:data] || {})
    attrs
  end

  def item_layout
    if vertical?
      cn("flex gap-3", { "pb-8" => !last? && @stepper.connector?, "pb-5" => !last? && !@stepper.connector? })
    elsif center?
      "flex flex-1 flex-col items-center text-center"
    else
      cn("flex flex-col", last? ? "shrink-0" : "flex-1")
    end
  end

  def indicator_classes
    cn("relative z-10 flex shrink-0 items-center justify-center rounded-full",
       "transition-[background-color,border-color,color,box-shadow] duration-300 motion-reduce:transition-none",
       INDICATOR[@stepper.variant],
       { "mt-1" => dot? && vertical? })
  end

  # The number (or the step's icon) for steps to come and the current one; a
  # tick once done, "!" on an error, a spinner while it's being checked.
  def glyph_classes(state)
    shown = {
      number: "group-data-[status=complete]/step:hidden group-data-[status=error]/step:hidden " \
              "group-data-[status=loading]/step:hidden",
      complete: "hidden group-data-[status=complete]/step:flex",
      error: "hidden group-data-[status=error]/step:flex",
      loading: "hidden group-data-[status=loading]/step:flex"
    }
    cn("items-center justify-center", shown[state], { GLYPH => state != :number })
  end

  def text_classes
    cn("flex min-w-0 flex-col gap-0.5",
       if vertical? then dot? ? "flex-1" : "flex-1 pt-1.5"
       elsif center? then "mt-3 px-2"
       else "mt-3 pr-4"
       end,
       { "sr-only" => !@stepper.labels?, "@max-md/stepper:sr-only" => !vertical? && @stepper.labels? })
  end

  def title_classes
    cn("text-sm font-medium text-foreground transition-colors duration-300",
       "group-data-[status=upcoming]/step:text-muted-foreground group-data-[status=error]/step:text-destructive",
       { "underline-offset-4 group-hover/link:underline" => link? })
  end

  def description_classes
    "text-sm text-muted-foreground group-data-[status=error]/step:text-destructive/90"
  end

  def link_classes
    "group/link flex w-fit rounded-sm outline-none focus-visible:ring-[3px] focus-visible:ring-ring/40"
  end

  def connector? = @stepper.connector? && !last?

  # The line on to the next step: a grey track, and a fill that grows along it
  # once this step is done.
  def connector_classes
    if vertical?
      cn("absolute w-0.5 -translate-x-1/2 overflow-hidden rounded-full bg-border",
         dot? ? "left-1.5 top-6 bottom-1" : "left-4 top-10 bottom-2")
    elsif center?
      cn("absolute h-0.5 -translate-y-1/2 overflow-hidden rounded-full bg-border",
         dot? ? "top-1.5 left-[calc(50%+1rem)] right-[calc(-50%+1rem)]"
              : "top-4 left-[calc(50%+1.75rem)] right-[calc(-50%+1.75rem)]")
    else
      "mx-3 h-0.5 flex-1 overflow-hidden rounded-full bg-border"
    end
  end

  def connector_fill_classes
    cn("block size-full bg-primary transition-transform duration-500 ease-out motion-reduce:transition-none",
       vertical? ? "origin-top scale-y-0 group-data-[status=complete]/step:scale-y-100"
                 : "origin-left scale-x-0 group-data-[status=complete]/step:scale-x-100 rtl:origin-right")
  end

  def head_classes
    vertical? || center? ? "contents" : "flex items-center"
  end

  def panel_attrs
    @stepper.panel_attrs(self).merge(class: cn(PANEL_CLASSES, "pt-4"))
  end

  # Each state's words for screen readers, shown (to them) only in that state.
  STATUS_TEXT = {
    complete: [ "Completed", "hidden group-data-[status=complete]/step:inline" ],
    current:  [ "Current step", "hidden group-data-[status=current]/step:inline" ],
    upcoming: [ "Not started", "hidden group-data-[status=upcoming]/step:inline" ],
    error:    [ "Needs attention", "hidden group-data-[status=error]/step:inline" ],
    loading:  [ "Checking", "hidden group-data-[status=loading]/step:inline" ]
  }.freeze

  def status_texts
    STATUS_TEXT.map { |state, (default, shown)| [ t("ui.stepper.#{state}", default: default), "sr-only #{shown}" ] }
  end
end
