# frozen_string_literal: true

class UI::Card::Footer < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def root_attrs
    { **@html_attrs, class: cn("flex items-center rounded-b-xl border-t bg-muted/50 p-(--card-spacing)",
                             @user_class),
      data: { slot: "card-footer", **(@html_attrs[:data] || {}) } }
  end
end
