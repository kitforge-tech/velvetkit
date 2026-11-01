# frozen_string_literal: true

# A site's main navigation. Hover a trigger with a mouse (or click, or press
# Enter / ArrowDown) to open its panel; Escape, a click outside or Tab away
# closes it. Panels follow their trigger as the page scrolls, and open
# upwards when there isn't room below.
class UI::NavigationMenuPreview < ViewComponent::Preview
  # A sticky site header with several menus, on a page long enough to
  # scroll, and a second menu in the footer whose panels open upwards.
  #
  # @label Site header
  # @param open_delay  number
  # @param close_delay number
  def playground(open_delay: 150, close_delay: 200)
    render_with_template(locals: { open_delay: open_delay.to_i, close_delay: close_delay.to_i })
  end

  # @label Simple
  def simple; render_with_template; end

  # @label Custom panel
  def custom_panel; render_with_template; end
end
