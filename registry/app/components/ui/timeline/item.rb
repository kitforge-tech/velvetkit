# frozen_string_literal: true

# One entry in a UI::Timeline: its marker, its title, when it happened, and the
# line on to the next entry. Its block is shown under the title, for anything
# more than `description:` (a link, a note, a badge).
#
# `status:` is :complete (the default, since most entries record something that
# has happened), :current, :upcoming or :error. `icon:` draws an icon in place
# of the status's own mark; a :dot timeline draws no icons.
#
# In a :colored timeline each circle takes the next colour in COLORS, or the one
# `color:` names, for colours that mean something (:emerald for stock received,
# :rose for written off). :upcoming and :error keep their own look, so a failure
# always reads as one.
#
# `time:` is a Time or Date, shown with the locale's :long format inside a
# <time> element; `time_label:` changes the words but keeps the machine-readable
# date ("2 hours ago"). A String is shown as it is, for what isn't a date yet
# ("Expected Friday").
class UI::Timeline::Item < UI::Base
  STATUSES = %i[complete current upcoming error].freeze

  ICONS = { complete: "check", error: "x" }.freeze

  # Written out in full, status by status, so Tailwind finds every class.
  MARKER = {
    default: {
      complete: "size-8 bg-primary text-primary-foreground",
      current:  "size-8 border-2 border-primary bg-background text-primary ring-4 ring-primary/15",
      upcoming: "size-8 bg-muted text-muted-foreground",
      error:    "size-8 bg-destructive text-white ring-4 ring-destructive/15"
    },
    dot: {
      complete: "mt-1 size-3 bg-primary",
      current:  "mt-1 size-3 border-2 border-primary bg-background ring-4 ring-primary/15",
      upcoming: "mt-1 size-3 bg-muted-foreground/30",
      error:    "mt-1 size-3 bg-destructive ring-4 ring-destructive/15"
    }
  }.freeze

  # Each colour's circle, then the ring it wears as the current item.
  COLORS = {
    blue:    [ "bg-blue-600 text-white", "ring-4 ring-blue-600/20" ],
    emerald: [ "bg-emerald-600 text-white", "ring-4 ring-emerald-600/20" ],
    amber:   [ "bg-amber-600 text-white", "ring-4 ring-amber-600/20" ],
    violet:  [ "bg-violet-600 text-white", "ring-4 ring-violet-600/20" ],
    rose:    [ "bg-rose-600 text-white", "ring-4 ring-rose-600/20" ],
    teal:    [ "bg-teal-600 text-white", "ring-4 ring-teal-600/20" ]
  }.freeze

  TITLE = {
    complete: "text-foreground",
    current:  "text-foreground",
    upcoming: "text-muted-foreground",
    error:    "text-destructive"
  }.freeze

  STATUS_TEXT = {
    complete: "Completed",
    current:  "In progress",
    upcoming: "Not started",
    error:    "Failed"
  }.freeze

  attr_reader :status, :title, :description, :icon

  def initialize(title:, description: nil, time: nil, time_label: nil, status: :complete, icon: nil,
                 color: nil, class: nil, **html_attrs)
    @title       = title
    @description = description
    @time        = time
    @time_label  = time_label
    @status      = STATUSES.include?(status&.to_sym) ? status.to_sym : :complete
    @icon        = icon
    @color       = color&.to_sym
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
  end

  def place(variant:, index:, last:)
    @variant = variant
    @index   = index
    @last    = last
  end

  def dot? = @variant == :dot
  def colored? = @variant == :colored && %i[complete current].include?(@status)
  def color = COLORS.key?(@color) ? @color : COLORS.keys[@index % COLORS.size]
  def connector? = !@last
  def description? = @description.present?
  def time? = @time.present?
  def date? = @time.respond_to?(:iso8601)
  def marker_icon = @icon || ICONS[@status]

  def time_text
    return @time_label if @time_label.present?

    date? ? I18n.l(@time, format: :long) : @time.to_s
  end

  def item_attrs
    attrs = @html_attrs.except(:data, :aria)
    attrs[:class] = cn("relative flex min-w-0 gap-3", { "pb-6" => connector? }, @user_class)
    attrs[:aria]  = { current: ("step" if @status == :current) }.compact.merge(@html_attrs[:aria] || {})
    attrs[:data]  = { slot: "timeline-item", status: @status }.merge(@html_attrs[:data] || {})
    attrs
  end

  def marker_classes
    # A circle is taller than a line of text. Its overhang doesn't count towards
    # the item's height, so the text alone sets the gap to the next item, however
    # much text there is. The last item has nothing below to overhang into.
    cn("relative z-10 flex shrink-0 items-center justify-center rounded-full", marker_look,
       { "-mb-2" => !dot? && connector? })
  end

  def marker_look
    return MARKER[dot? ? :dot : :default][@status] unless colored?

    fill, ring = COLORS[color]
    cn("size-8", fill, (ring if @status == :current))
  end

  # Unbroken from this marker to the next one, drawn in while the entry is done
  # (a plain line between colours, which would clash with any one of them).
  # A dot sits 0.25rem down its item, so the line runs that far into the next.
  # Placed from the start edge so it follows the marker in a right-to-left page.
  def connector_classes
    cn("absolute w-0.5",
       dot? ? "start-[calc(0.375rem-1px)] top-4 -bottom-1" : "start-[calc(1rem-1px)] top-8 bottom-0",
       @status == :complete && @variant != :colored ? "bg-primary" : "bg-border")
  end

  def text_classes
    cn("flex min-w-0 flex-1 flex-col gap-0.5", { "pt-1" => !dot? })
  end

  def title_classes
    cn("text-sm font-medium", TITLE[@status])
  end

  def status_text
    t("ui.timeline.#{@status}", default: STATUS_TEXT[@status])
  end
end
