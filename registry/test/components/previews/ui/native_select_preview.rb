# frozen_string_literal: true

class UI::NativeSelectPreview < ViewComponent::Preview
  SECTIONS = [ [ "Grade 8 A", 1 ], [ "Grade 8 B", 2 ], [ "Grade 9 A", 3 ] ].freeze

  # @label Playground
  # @param size select { choices: [sm, default, lg] }
  # @param label text
  # @param required toggle
  # @param disabled toggle
  # @param error toggle
  def playground(size: :default, label: "Section", required: false, disabled: false, error: false)
    render(UI::NativeSelect.new(name: "section_id", options: SECTIONS, prompt: "Choose a section",
                          size: size.to_sym, label: label, required: required,
                          disabled: disabled, error: error))
  end

  # @label Sizes
  def sizes; render_with_template; end

  # @label States
  def states; render_with_template; end
end
