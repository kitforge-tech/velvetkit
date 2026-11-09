# frozen_string_literal: true

class UI::Card::Title < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def root_attrs
    { **@html_attrs, class: cn("text-base leading-snug font-medium group-data-[size=sm]/card:text-sm",
                             @user_class),
      data: { slot: "card-title", **(@html_attrs[:data] || {}) } }
  end
end
