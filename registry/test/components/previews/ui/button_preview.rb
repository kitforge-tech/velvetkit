# frozen_string_literal: true

class UI::ButtonPreview < ViewComponent::Preview
  # @label Playground
  # @param text text "Button text"
  # @param variant select { choices: [default, destructive, outline, secondary, ghost, link] }
  # @param size select { choices: [default, sm, lg, icon] }
  # @param leading_icon select { choices: [none, lock, arrow-right, badge-check, eye, user] }
  # @param trailing_icon select { choices: [none, arrow-right, chevrons-up-down, eye, x] }
  # @param full_width toggle
  # @param loading toggle
  # @param disabled toggle
  def playground(text: "Click me", variant: :default, size: :default,
                 leading_icon: :none, trailing_icon: :none,
                 full_width: false, loading: false, disabled: false)
    render(UI::Button.new(
      variant: variant.to_sym, size: size.to_sym,
      full_width: full_width, loading: loading, disabled: disabled
    )) do |btn|
      btn.with_leading_icon(name: leading_icon.to_s)  unless leading_icon.to_s == "none"
      btn.with_trailing_icon(name: trailing_icon.to_s) unless trailing_icon.to_s == "none"
      text
    end
  end

  # @label All Variants
  def variants
    render_with_template
  end

  # @label All Sizes
  def sizes
    render_with_template
  end

  # @label With Leading Icon
  def with_leading_icon
    render_with_template
  end

  # @label With Trailing Icon
  def with_trailing_icon
    render_with_template
  end

  # @label With Both Icons
  def with_both_icons
    render_with_template
  end

  # @label Icon Only
  def icon_only
    render_with_template
  end

  # @label Loading
  def loading
    render_with_template
  end

  # @label Disabled
  def disabled
    render_with_template
  end
end
