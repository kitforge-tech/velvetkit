# frozen_string_literal: true

require "securerandom"

# Controls that belong together under one caption: a <fieldset> whose
# <legend> names the group, a hint under it and an error message for the
# group as a whole. Use it for a set of checkboxes, a block of settings or an
# address. RadioGroup and ToggleGroup render through it themselves when given
# `legend:`, `hint:` or `error:`.
#
#   <%= render(UI::Fieldset.new(legend: "Notifications", hint: "Where we tell you about replies.")) do %>
#     <%= render(UI::Checkbox.new(name: "notify[]", value: "email", label: "Email")) %>
#     <%= render(UI::Checkbox.new(name: "notify[]", value: "push", label: "Push")) %>
#   <% end %>
#
# `disabled: true` disables every control inside, natively. `error:` takes a
# message, or `true` to mark the group invalid without one. Bound to a form
# (`form:` + `field:`), the model's errors on that attribute are the message
# and its human name is the legend (`legend:` overrides it, `legend: false`
# opts out), the way UI::FormField does it for one control.
class UI::Fieldset < UI::Base
  def initialize(legend: nil, hint: nil, error: nil, required: false, disabled: false,
                 form: nil, field: nil, class: nil, **html_attrs)
    @required   = required
    @disabled   = disabled
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    # FormField already works out a label, hint and error, from a form or not;
    # the legend is that label.
    @details = UI::FormField.new(label: legend, hint: hint, error: error, form: form, field: field,
                                 for: html_attrs[:id] || "ui-fieldset-#{SecureRandom.hex(4)}")
  end

  def id = @details.control_id
  def legend_id = "#{id}-legend"
  def hint_id = @details.hint_id
  def error_id = @details.error_id

  def legend? = @details.render_label?
  def legend_text = @details.label_text
  def hint = @details.hint
  def error_message = @details.error_message

  # Whether there's anything to show around the controls. RadioGroup and
  # ToggleGroup render bare without it.
  def wrap? = legend? || hint.present? || error_message.present?

  def fieldset_attrs
    # A radiogroup takes aria-required and aria-invalid; a plain fieldset is a
    # group, which takes neither.
    radiogroup = @html_attrs[:role].to_s == "radiogroup"
    aria = {
      labelledby:  (legend_id if legend?),
      describedby: @details.describedby,
      required:    ("true" if radiogroup && @required),
      invalid:     ("true" if radiogroup && @details.error?)
    }.compact
    @html_attrs.except(:aria).merge(id: id, class: classes, disabled: @disabled,
                                    aria: aria.merge(@html_attrs[:aria] || {}))
  end

  def classes
    cn("flex min-w-0 flex-col gap-3", @user_class)
  end

  # The legend sits outside the fieldset's flex layout, so its own margin
  # spaces it: close to a hint, further from the controls.
  def legend_classes
    cn("text-sm font-medium leading-none", hint.present? ? "mb-1.5" : "mb-3",
       { "text-muted-foreground" => @disabled })
  end
end
