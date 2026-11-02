# frozen_string_literal: true

class UI::InputGroupPreview < ViewComponent::Preview
  # @label Playground
  # @param left_icon toggle
  # @param right_icon toggle
  # @param addon_icon text
  # @param align select { choices: [inline-start, inline-end] }
  # @param error toggle
  # @param disabled toggle
  def playground(left_icon: true, right_icon: false, addon_icon: "mail", align: "inline-start", error: false, disabled: false)
    render_with_template(locals: { left_icon: left_icon, right_icon: right_icon, addon_icon: addon_icon, align: align, error: error, disabled: disabled })
  end

  # @label All Addons
  def addons; render_with_template; end
end
