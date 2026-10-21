# frozen_string_literal: true

class UI::InputPreview < ViewComponent::Preview
  # @label Playground
  # @param type    select { choices: [text, email, password, number, search] }
  # @param size    select { choices: [sm, default, lg] }
  # @param variant select { choices: [default, error, with_label] }
  # @param label text
  # @param label_size select { choices: [xs, sm, default, lg] }
  # @param label_weight select { choices: [normal, medium, semibold] }
  # @param required toggle
  # @param error   toggle
  # @param disabled toggle
  # @param placeholder text
  def playground(type: :text, size: :default, variant: :default,
                 label: nil, label_size: :default, label_weight: :medium,
                 required: false, error: false, disabled: false,
                 placeholder: "Enter value…")
    render(UI::Input.new(type: type.to_sym, size: size.to_sym, variant: variant.to_sym,
                         label: label, label_size: label_size.to_sym, label_weight: label_weight.to_sym,
                         required: required, error: error, disabled: disabled,
                         placeholder: placeholder))
  end

  # @label All Sizes
  def sizes; render_with_template; end

  # @label States
  def states; render_with_template; end

  # @label With Labels
  def with_labels; render_with_template; end
end
