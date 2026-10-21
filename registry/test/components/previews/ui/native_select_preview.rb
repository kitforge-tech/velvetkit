# frozen_string_literal: true

class UI::NativeSelectPreview < ViewComponent::Preview
  SECTIONS = [ [ "Design", 1 ], [ "Engineering", 2 ], [ "Marketing", 3 ] ].freeze

  # @label Playground
  # @param size select { choices: [sm, default, lg] }
  # @param label text
  # @param required toggle
  # @param disabled toggle
  # @param error toggle
  def playground(size: :default, label: "Team", required: false, disabled: false, error: false)
    render(UI::NativeSelect.new(name: "team_id", options: SECTIONS, prompt: "Choose a team",
                          size: size.to_sym, label: label, required: required,
                          disabled: disabled, error: error))
  end

  # @label Sizes
  def sizes; render_with_template; end

  # @label States
  def states; render_with_template; end
end
