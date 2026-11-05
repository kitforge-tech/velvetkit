# frozen_string_literal: true

# What happened, and what's still to come, as a list down the page: an order's
# progress, a product's stock history, an account's activity. UI::Stepper is
# for moving someone through a form; this only records.
#
#   <%= render(UI::Timeline.new(label: "Order history")) do |timeline| %>
#     <% timeline.with_item(title: "Paid", time: order.paid_at, icon: "credit-card") %>
#     <% timeline.with_item(title: "Shipped", status: :current) do %>
#       <%= link_to "Track parcel", order.tracking_url %>
#     <% end %>
#     <% timeline.with_item(title: "Delivered", status: :upcoming, time: "Expected Friday") %>
#   <% end %>
#
# Items show in the order they're given, so newest-first is up to the caller.
# `variant: :default` draws a circle holding the item's icon or a mark for its
# status, `:dot` a small dot, for a long log, and `:colored` the same circles in
# a different colour each. Each item's options are on UI::Timeline::Item.
class UI::Timeline < UI::Base
  VARIANTS = %i[default dot colored].freeze

  renders_many :items, UI::Timeline::Item

  def initialize(variant: :default, label: nil, class: nil, **html_attrs)
    @variant    = VARIANTS.include?(variant.to_sym) ? variant.to_sym : :default
    @label      = label
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def before_render
    items.each_with_index { |item, index| item.place(variant: @variant, index: index, last: index == items.size - 1) }
  end

  def root_attrs
    attrs = @html_attrs.except(:data, :aria)
    attrs[:class] = cn("flex w-full flex-col", @user_class)
    attrs[:aria]  = { label: @label || t("ui.timeline.label", default: "Timeline") }.merge(@html_attrs[:aria] || {})
    attrs[:data]  = { slot: "timeline", variant: @variant }.merge(@html_attrs[:data] || {})
    attrs
  end
end
