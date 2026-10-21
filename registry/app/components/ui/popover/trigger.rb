# frozen_string_literal: true

class UI::Popover::Trigger < UI::Base
  def initialize(variant: :outline, size: :default, class: nil, **html_attrs)
    @variant = variant
    @size = size
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_popover_context(popover)
    @popover = popover
    @id = @html_attrs[:id] || "ui-popover-trigger-#{popover.id}"
  end

  def button_options
    @html_attrs.merge(
      id: @id,
      class: @user_class,
      variant: @variant || :default,
      size: @size,
      "aria-haspopup" => true,
      "aria-expanded" => false,
      "aria-controls" => "ui-popover-content-#{@popover.id}",
      "data-ui--popover-target" => "trigger",
      "data-action" => "click->ui--popover#toggle"
    )
  end
end
