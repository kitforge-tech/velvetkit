# frozen_string_literal: true

class UI::Card::Header < UI::Base
  # Two columns once there's an action, which then spans the title and
  # description rows.
  CLASSES = "grid auto-rows-min items-start gap-1 rounded-t-xl px-(--card-spacing) " \
            "has-data-[slot=card-action]:grid-cols-[1fr_auto] [.border-b]:pb-(--card-spacing)"

  renders_one :title, UI::Card::Title
  renders_one :description, UI::Card::Description
  renders_one :action, UI::Card::Action

  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def root_attrs
    { **@html_attrs, class: cn(CLASSES, @user_class),
      data: { slot: "card-header", **(@html_attrs[:data] || {}) } }
  end
end
