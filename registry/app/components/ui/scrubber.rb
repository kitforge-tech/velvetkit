# frozen_string_literal: true

# A rail down the side of a long list for jumping through it by date: the
# years marked on it, a dot for each month, and the date under the pointer.
#
#   <%= render(UI::Scrubber.new(label: "Jump to a date", for: "library", class: "fixed inset-y-16 end-0")) do |scrubber| %>
#     <% @months.each do |month| %>
#       <% scrubber.with_mark(href: "##{month.id}", label: month.name, major: (month.year if month.january?)) %>
#     <% end %>
#   <% end %>
#
# Each mark is a link to a heading in the list (`href: "#march-2026"`), placed
# on the rail as far down as that heading is in the list, so a busy month takes
# more of the rail. `major:` is the text shown beside the mark, such as the
# year; the others are dots. A line follows how far down the list is.
#
# Dragging along the rail scrolls the list with it, the way a scrollbar does,
# with the date under the pointer beside it. From the keyboard it's one stop:
# ↑ and ↓ move between the marks, Home and End to the ends, and Enter goes
# there. `for:` is the id of the element that scrolls, or the window when
# it's left out.
class UI::Scrubber < UI::Base
  Mark = Struct.new(:href, :label, :major, keyword_init: true)

  def initialize(label:, for: nil, class: nil, **html_attrs)
    @label      = label
    @for        = binding.local_variable_get(:for)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @marks      = []
  end

  attr_reader :marks

  def with_mark(href:, label:, major: nil)
    @marks << Mark.new(href: href, label: label, major: major)
    nil
  end

  def before_render = content

  def render? = true

  def root_attrs
    attrs = @html_attrs.except(:data, :aria)
    attrs[:class] = cn("group/scrubber relative w-14 touch-none select-none", @user_class)
    attrs[:aria] = { label: @label }.merge(@html_attrs[:aria] || {})
    attrs[:data] = { slot: "scrubber", controller: "ui--scrubber", "ui--scrubber-for-value": @for,
                     action: "keydown->ui--scrubber#keydown resize@window->ui--scrubber#layout" }
                   .merge(@html_attrs[:data] || {})
    attrs
  end

  def mark_attrs(mark, index)
    { href: mark.href, tabindex: index.zero? ? 0 : -1,
      class: cn("absolute end-0 top-0 flex h-4 -translate-y-1/2 items-center justify-end rounded-sm pe-2 outline-none " \
                "invisible group-data-[ready]/scrubber:visible focus-visible:ring-2 focus-visible:ring-primary",
                mark.major ? "min-w-8 text-[11px] font-medium text-muted-foreground" : "w-4"),
      aria: { label: mark.label },
      data: { "ui--scrubber-target": "mark", label: mark.label, major: mark.major.present? } }
  end
end
