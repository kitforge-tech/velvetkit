# frozen_string_literal: true

# A surface that groups one thing: a form, a stat, a person, an event.
#
#   <%= render(UI::Card.new) do |card| %>
#     <% card.with_header do |header| %>
#       <% header.with_title { "Team" } %>
#       <% header.with_description { "Who can see this project." } %>
#       <% header.with_action { render(UI::Button.new(size: :sm)) { "Invite" } } %>
#     <% end %>
#     <% card.with_content { ... } %>
#     <% card.with_footer { ... } %>
#   <% end %>
#
# `with_action` sits at the top right of the header. `with_image(src:, alt:)`
# runs edge to edge across the top. The footer is a tinted band along the
# bottom.
#
# `size: :sm` is tighter, with a smaller title. `spacing:` sets the gap between
# the parts and their inset, in Tailwind's steps (4 is 16px, 6 is 24px). Inside
# the card it's the CSS variable --card-spacing, so content can reach the
# edges with `-mx-(--card-spacing)` and stay lined up with the rest.
#
# A card with no parts, just a block, is a bare surface with no padding of its
# own: `render(UI::Card.new(class: "p-6")) { ... }`.
#
# It doesn't clip its contents, so a menu or date picker opened inside isn't
# cut off at the card's edge.
class UI::Card < UI::Base
  SPACING = { default: 4, sm: 3 }.freeze

  # Only once the card has parts. `^=` matches card-header, card-content and
  # so on, as direct children, which a block of the app's own never is.
  # The footer and image reach the card's edge; those two are `!` because
  # Tailwind's order for these variants would otherwise let py win.
  CLASSES = "group/card rounded-xl bg-card text-card-foreground ring-1 ring-foreground/10 " \
            "has-[>[data-slot^=card-]]:flex has-[>[data-slot^=card-]]:flex-col " \
            "has-[>[data-slot^=card-]]:gap-(--card-spacing) has-[>[data-slot^=card-]]:py-(--card-spacing) " \
            "has-[>[data-slot^=card-]]:text-sm has-[>[data-slot=card-footer]]:pb-0! " \
            "has-[>[data-slot=card-image]:first-child]:pt-0!"

  renders_one :image, lambda { |src:, alt:, class: nil, **attrs|
    UI::Image.new(src: src, alt: alt, rounded: :none, data: { slot: "card-image" },
                  class: cn("aspect-video w-full rounded-t-xl object-cover", binding.local_variable_get(:class)), **attrs)
  }
  renders_one :header, UI::Card::Header
  renders_one :card_content, UI::Card::Content
  renders_one :footer, UI::Card::Footer

  alias_method :with_content, :with_card_content

  def initialize(size: :default, spacing: nil, class: nil, **html_attrs)
    @size       = SPACING.key?(size.to_sym) ? size.to_sym : :default
    @spacing    = spacing || SPACING[@size]
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def root_attrs
    { **@html_attrs, class: cn(CLASSES, @user_class),
      style: [ "--card-spacing: calc(var(--spacing) * #{@spacing})", @html_attrs[:style] ].compact.join("; "),
      data: { slot: "card", size: @size, **(@html_attrs[:data] || {}) } }
  end
end
