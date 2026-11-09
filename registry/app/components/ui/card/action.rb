# frozen_string_literal: true

# What goes at the top right of a card's header: a button, a badge, a link.
class UI::Card::Action < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def root_attrs
    { **@html_attrs, class: cn("col-start-2 row-span-2 row-start-1 self-start justify-self-end", @user_class),
      data: { slot: "card-action", **(@html_attrs[:data] || {}) } }
  end
end
