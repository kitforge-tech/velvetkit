# frozen_string_literal: true

require "securerandom"

# UI::PasswordInput — password field with a show/hide toggle.
#
# Composes UI::InputGroup so the border, focus ring and disabled styling stay
# identical to every other grouped input; the toggle is an inline-end addon
# driven by the `ui--password-visibility` Stimulus controller.
#
# Velvet::PasswordInput hardcoded a placeholder (shadowing the caller's) and
# accepted `rounded:`/`full_width:`/`variant:`/`size:`/`mb:` that nothing read.
# Those are gone. Its toggle was also dead — no controller was ever registered.
#
# Usage:
#   <%= render(UI::PasswordInput.new(form: f, field: :password, required: true)) %>
#   <%= render(UI::PasswordInput.new(name: "user[password]")) %>
class UI::PasswordInput < UI::Base
  def initialize(form: nil, field: nil, label: nil, hint: nil, required: false,
                 disabled: false, error: nil, class: nil, **html_attrs)
    @form       = form
    @field      = field
    @label      = label
    # The <input> is wrapped by the group's border, so the label has to sit
    # outside it; give the field a stable id for the label to point at.
    @input_id   = html_attrs[:id] || "ui-password-#{SecureRandom.hex(4)}"
    @required   = required
    @disabled   = disabled
    @error      = error
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @wrapper    = UI::FormField.new(label: label, hint: hint, error: error,
                                    required: required, disabled: disabled,
                                    form: form, field: field, for: @input_id)
  end

  attr_reader :wrapper

  def group_component
    UI::InputGroup.new(
      class: @user_class,
      data: { controller: "ui--password-visibility" }
    )
  end

  def form_field?
    @form.present? && @field.present?
  end

  def field_options
    {
      type: :password,
      id: @input_id,
      form: @form,
      field: @field,
      label: false,
      required: @required,
      disabled: @disabled,
      error: wrapper.error?,
      "aria-describedby": wrapper.describedby,
      data: { "ui--password-visibility-target" => "input" },
      **@html_attrs
    }
  end

  def toggle_button_options
    {
      disabled: @disabled,
      aria: { label: I18n.t("ui.password_input.show", default: "Show password"), pressed: "false" },
      data: {
        action: "ui--password-visibility#toggle",
        "ui--password-visibility-target" => "toggle"
      }
    }
  end
end
