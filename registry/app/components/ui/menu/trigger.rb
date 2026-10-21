# frozen_string_literal: true

class UI::Menu::Trigger < UI::Base
  def initialize(variant: :outline, size: :default, class: nil, **html_attrs)
    @variant = variant
    @size = size
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_menu_context(menu)
    @menu = menu
    @id = @html_attrs[:id] || "ui-menu-trigger-#{menu.id}"
  end

  def button_options
    @html_attrs.merge(
      id: @id,
      class: @user_class,
      variant: @variant,
      size: @size,
      "aria-haspopup" => true,
      "aria-expanded" => false,
      "aria-controls" => "ui-menu-content-#{@menu.id}",
      "data-ui--menu-target" => "trigger",
      "data-action" => "click->ui--menu#toggle keydown->ui--menu#triggerKeydown"
    )
  end
end
