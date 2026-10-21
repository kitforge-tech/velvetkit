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
  def initialize(form: nil, field: nil, label: nil, required: false,
                 disabled: false, error: false, class: nil, **html_attrs)
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
  end

  def group_component
    UI::InputGroup.new(
      class: @user_class,
      data: { controller: "ui--password-visibility" }
    )
  end

  # Same convention as UI::Input: bound to a form object the attribute name
  # supplies the label text; `label:` overrides it, `label: false` opts out.
  def render_label?
    return false if @label == false

    @label.present? || form_field?
  end

  def form_field?
    @form.present? && @field.present?
  end

  def label_text
    return @label if @label.is_a?(String) && @label.present?
    return nil unless form_field?

    object = @form.object
    if object.respond_to?(:class) && object.class.respond_to?(:human_attribute_name)
      object.class.human_attribute_name(@field)
    else
      @field.to_s.humanize
    end
  end

  def label_component
    UI::Label.new(for: @input_id, required: @required, disabled: @disabled)
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
      error: @error,
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
