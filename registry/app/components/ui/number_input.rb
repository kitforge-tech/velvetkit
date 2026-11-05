# frozen_string_literal: true

require "securerandom"

# A number field with - and + buttons, for quantities and stock counts. It's a
# real <input type="number">, so typing, arrow keys, `min:`, `max:`, `step:` and
# form validation all work as usual, and it takes the same label, hint, error
# and form-builder options as UI::Input.
#
#   <%= render(UI::NumberInput.new(form: f, field: :quantity, min: 1, max: 99, class: "w-32")) %>
#   <%= render(UI::NumberInput.new(name: "weight", value: 1.5, step: 0.25, size: :lg)) %>
#
# Holding a button keeps counting. Each step fires `input`, and `change` fires
# once when the button is let go, so a form that submits on change sends one
# request however long the button is held. A button turns off at its limit.
#
# The buttons are left out of the tab order: arrow keys do the same job from
# the field, and tabbing along a row of quantities shouldn't stop three times.
# Screen readers can still reach them. `size: :lg` is for touch screens.
class UI::NumberInput < UI::Base
  SIZES = {
    sm:      { group: "h-8 [&>input]:text-xs", button: "w-8", icon: :xs },
    default: { group: "h-9", button: "w-9", icon: :sm },
    lg:      { group: "h-12 [&>input]:text-base", button: "w-12", icon: :default }
  }.freeze

  # Reaches the field from the group, because UI::InputGroup::Field sets its own
  # classes. The browser's spinner goes, in favour of the buttons.
  GROUP_CLASSES = "[&>input]:h-full [&>input]:min-w-0 [&>input]:px-1 [&>input]:text-center " \
                  "[&>input]:[appearance:textfield] [&>input::-webkit-inner-spin-button]:appearance-none " \
                  "[&>input::-webkit-outer-spin-button]:appearance-none"

  # The buttons fill the group's height, rather than the addon's usual inset.
  ADDON_CLASSES = "cursor-default self-stretch p-0 has-[>button]:ml-0 has-[>button]:mr-0"

  STEP_BUTTON = {
    decrement: { label: "Decrease", direction: "down", edge: "rounded-e-none border-e border-input" },
    increment: { label: "Increase", direction: "up", edge: "rounded-s-none border-s border-input" }
  }.freeze

  def initialize(size: :default, min: nil, max: nil, step: nil, form: nil, field: nil, label: nil, hint: nil,
                 required: false, disabled: false, error: nil, class: nil, **html_attrs)
    @size       = SIZES.key?(size.to_sym) ? size.to_sym : :default
    @min        = min
    @max        = max
    @step       = step
    @form       = form
    @field      = field
    @required   = required
    @disabled   = disabled
    # The <input> is wrapped by the group's border, so the label has to sit
    # outside it; give the field a stable id for the label to point at.
    @input_id   = html_attrs[:id] || "ui-number-input-#{SecureRandom.hex(4)}"
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @wrapper    = UI::FormField.new(label: label, hint: hint, error: error,
                                    required: required, disabled: disabled,
                                    form: form, field: field, for: @input_id)
  end

  attr_reader :wrapper

  def group_component
    UI::InputGroup.new(class: cn(GROUP_CLASSES, SIZES[@size][:group], @user_class),
                       data: { controller: "ui--number-input" })
  end

  def field_options
    { type: :number, form: @form, field: @field, label: false, required: @required, disabled: @disabled,
      error: wrapper.error?, "aria-describedby": wrapper.describedby, min: @min, max: @max, step: @step,
      inputmode: inputmode, **@html_attrs, id: @input_id, data: field_data }.compact
  end

  def step_button_options(kind)
    button = STEP_BUTTON.fetch(kind)
    { variant: :ghost, disabled: @disabled || @html_attrs[:readonly].present?, tabindex: -1,
      # Lifted on focus, so the neighbouring field doesn't cover the kit's ring.
      class: cn("relative h-full p-0 text-foreground select-none touch-manipulation focus:z-10 disabled:opacity-40",
                SIZES[@size][:button], button[:edge]),
      aria: { label: t("ui.number_input.#{kind}", default: button[:label]), controls: @input_id },
      data: { "ui--number-input-target": kind.to_s, "ui--number-input-direction-param": button[:direction],
              action: "pointerdown->ui--number-input#press click->ui--number-input#click" } }
  end

  def icon_size = SIZES[@size][:icon]

  private

  # The keypad a phone shows. Its number pad has no minus sign, so that's only
  # for fields that can't go below zero.
  def inputmode
    return "decimal" if @step.to_s == "any" || @step.to_f % 1 != 0
    return "numeric" if @min && @min.to_f >= 0

    nil
  end

  def field_data
    data = @html_attrs[:data] || {}
    action = [ "input->ui--number-input#sync change->ui--number-input#sync", data[:action] ].compact.join(" ")
    data.merge("ui--number-input-target": "input", action: action)
  end
end
