# frozen_string_literal: true

# A row of cards that scrolls sideways: highlights, albums, related products.
#
#   <%= render(UI::Carousel.new(label: "Highlights", item_class: "w-64")) do |carousel| %>
#     <% @highlights.each do |highlight| %>
#       <% carousel.with_item { render(highlight) } %>
#     <% end %>
#   <% end %>
#
# It's a scroll-snap strip, so it swipes on a touch screen and scrolls with a
# trackpad with no script involved, and each card stops at the edge. Previous
# and next buttons scroll a strip's width at a time, and each shows only while
# there's more to see that way. `item_class:` sizes the cards ("w-64",
# "basis-1/3"); they're as wide as their content otherwise.
class UI::Carousel < UI::Base
  renders_many :items

  def initialize(label:, item_class: nil, gap: 3, class: nil, **html_attrs)
    @label      = label
    @item_class = item_class
    @gap        = gap
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  # Written out in full so Tailwind finds them.
  GAPS = { 2 => "gap-2", 3 => "gap-3", 4 => "gap-4", 6 => "gap-6" }.freeze

  def root_attrs
    attrs = @html_attrs.except(:data, :aria)
    attrs[:role] = "region"
    attrs[:class] = cn("group/carousel relative min-w-0", @user_class)
    attrs[:aria] = { label: @label, roledescription: t("ui.carousel.roledescription", default: "carousel") }
                   .merge(@html_attrs[:aria] || {})
    attrs[:data] = { slot: "carousel", controller: "ui--carousel",
                     action: "resize@window->ui--carousel#update" }.merge(@html_attrs[:data] || {})
    attrs
  end

  # The padding gives the cards' focus rings room, and the margin takes it back.
  def track_classes
    cn("-m-1 flex snap-x snap-mandatory scroll-px-1 overflow-x-auto scroll-smooth p-1 motion-reduce:scroll-auto",
       "[scrollbar-width:none] [&::-webkit-scrollbar]:hidden", GAPS.fetch(@gap, GAPS[3]))
  end

  def item_classes = cn("shrink-0 snap-start", @item_class)

  def button_attrs(direction)
    edge = direction == :previous ? "start-0 -translate-x-1/2 rtl:translate-x-1/2" : "end-0 translate-x-1/2 rtl:-translate-x-1/2"
    { variant: :outline, size: :icon,
      class: cn("absolute top-1/2 z-10 hidden -translate-y-1/2 rounded-full bg-background shadow-md sm:inline-flex [&[hidden]]:hidden!", edge),
      hidden: true,
      aria: { label: t("ui.carousel.#{direction}", default: direction == :previous ? "Previous" : "Next"),
              controls: track_id },
      data: { action: "ui--carousel##{direction}", "ui--carousel-target": direction } }
  end

  def track_id = @track_id ||= "carousel-#{SecureRandom.hex(4)}"
end
