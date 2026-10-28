# frozen_string_literal: true

class UI::TextareaPreview < ViewComponent::Preview
  # @label Playground
  # @param size     select { choices: [sm, default, lg] }
  # @param resize   select { choices: [vertical, none, both] }
  # @param rows     number
  # @param autogrow toggle
  # @param label    text
  # @param required toggle
  # @param error    toggle
  # @param disabled toggle
  # @param placeholder text
  def playground(size: :default, resize: :vertical, rows: 3, autogrow: false,
                 label: "Message", required: false, error: false, disabled: false,
                 placeholder: "Write a message…")
    render(UI::Textarea.new(size: size.to_sym, resize: resize.to_sym, rows: rows.to_i, autogrow: autogrow,
                            label: label, required: required, error: error, disabled: disabled,
                            placeholder: placeholder))
  end

  # @label Default
  def default; render_with_template; end

  # @label Grows with its text
  def autogrow; render_with_template; end

  # @label States
  def states; render_with_template; end

  # @label All Sizes
  def sizes; render_with_template; end
end
