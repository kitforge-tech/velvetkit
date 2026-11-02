# frozen_string_literal: true

class UI::IconPreview < ViewComponent::Preview
  # @label Playground
  # @param icon text "An SVG in app/assets/icons, without .svg"
  # @param size select { choices: [xs, sm, default, lg, xl] }
  def playground(icon: "menu", size: :default)
    render(UI::Icon.new(name: icon, size: size.to_sym))
  end

  # @label All Sizes
  def sizes
    render_with_template
  end

  # @label Common Icons
  def common
    render_with_template
  end

  # A label makes the icon an image with that accessible name. Without one
  # it is decorative and hidden from screen readers, which is right next to
  # text that already says the same thing.
  # @label With a Label
  def labelled
    render_with_template
  end

  # An icon with no SVG in app/assets/icons draws this dashed square, and
  # the log names the file. Add it with `bin/rails generate velvetkit:icons`.
  # @label Missing Icon
  def missing
    render_with_template
  end
end
