# frozen_string_literal: true

class UI::SelectPreview < ViewComponent::Preview
  PLANS = [ [ "Free", "free" ], [ "Team", "team" ], [ "Business", "business" ], [ "Enterprise", "enterprise" ] ].freeze

  # @label Playground
  # @param size select { choices: [sm, default, lg] }
  # @param prompt text
  # @param required toggle
  # @param error toggle
  # @param disabled toggle
  # @param searchable toggle
  # @param multiple toggle
  def playground(size: :default, prompt: "Choose a plan", required: false, error: false, disabled: false,
                 searchable: false, multiple: false)
    render(UI::Select.new(name: "plan", label: "Plan", options: PLANS, prompt: prompt.presence,
                          size: size.to_sym, required: required, error: error, disabled: disabled,
                          searchable: searchable, multiple: multiple))
  end

  # @label Default
  def default
    render_with_template
  end

  # @label States
  def states
    render_with_template
  end

  # @label Sizes
  def sizes
    render_with_template
  end

  # @label Searchable
  def long_list
    render_with_template
  end

  # @label Multiple
  def multiple
    render_with_template
  end
end
