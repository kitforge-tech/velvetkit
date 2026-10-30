# frozen_string_literal: true

require "securerandom"

# UI::FileField — a drag-and-drop dropzone over a native file input.
#
# The input itself is sr-only, not hidden: it stays in the accessibility
# tree and keyboard/native-picker behavior (Tab, Enter/Space, the OS file
# dialog) comes from the real <input type="file">, same as every other
# styled-native-control component here. The dropzone is a <label> around it,
# so clicking anywhere in it opens the picker without any JS, and the
# ui--file-field controller only adds what a label can't: drag-over
# highlighting and listing the chosen file names.
class UI::FileField < UI::Base
  def initialize(multiple: false, accept: nil,
                  label: nil, label_size: :default, label_weight: :medium,
                  hint: nil, required: false, error: nil, disabled: false,
                  form: nil, field: nil,
                  class: nil, **html_attrs)
    @form        = form
    @field       = field
    @multiple    = multiple
    @accept      = accept
    @required    = required
    @disabled    = disabled
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
    @wrapper     = UI::FormField.new(label: label, hint: hint, error: error,
                                     required: required, disabled: disabled,
                                     label_size: label_size, label_weight: label_weight,
                                     form: form, field: field)
    @input_id    = @html_attrs[:id] || "ui-file-field-#{SecureRandom.hex(4)}"
    @html_attrs[:id] = @input_id
    @wrapper.for = @input_id
  end

  attr_reader :wrapper

  def form_field?
    @form.present? && @field.present?
  end

  def dropzone_classes
    cn(
      "relative flex cursor-pointer flex-col items-center gap-2 rounded-lg border-2 border-dashed p-6 text-center transition-colors",
      "border-input hover:bg-accent/50",
      "data-[drag=true]:border-primary data-[drag=true]:bg-primary/5",
      { "border-destructive" => wrapper.error?,
        "pointer-events-none opacity-50" => @disabled },
      @user_class
    )
  end

  def html_options
    opts = @html_attrs.dup
    opts[:type]            = "file"
    opts[:class]           = "sr-only"
    opts[:multiple]        = true if @multiple
    opts[:accept]          = @accept if @accept
    opts[:disabled]        = true if @disabled
    opts[:required]        = true if @required
    opts[:"data-ui--file-field-target"] = "input"
    opts[:"data-action"]   = "change->ui--file-field#updateNames"
    opts[:"aria-invalid"]  = "true" if wrapper.error?
    opts[:"aria-describedby"] = wrapper.describedby if wrapper.describedby
    opts
  end

  # The builder derives the name itself, so drop any explicit one.
  def form_field_options
    html_options.except(:name, :type)
  end
end
