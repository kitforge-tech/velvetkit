# frozen_string_literal: true

class UI::Card::Content < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def root_attrs
    { **@html_attrs, class: cn("px-(--card-spacing)",
                             @user_class),
      data: { slot: "card-content", **(@html_attrs[:data] || {}) } }
  end
end
