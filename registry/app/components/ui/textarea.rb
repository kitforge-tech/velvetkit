# frozen_string_literal: true

require "securerandom"

# A multi-line text field, with the same label, hint, required, error and
# form-builder options as UI::Input.
#
# `autogrow: true` grows the box with its text (CSS field-sizing, no
# JavaScript); browsers without it keep `rows:` lines and scroll. Cap the
# height with a class such as `max-h-60`.
class UI::Textarea < UI::Base
  variants(
    base: "flex w-full rounded-md border border-input bg-background " \
          "text-foreground " \
          "placeholder:text-muted-foreground " \
          "#{UI::Base::FOCUS_RING} " \
          "disabled:cursor-not-allowed disabled:opacity-50",
    variants: {
      size: {
        sm:      "px-2.5 py-1.5 text-xs",
        default: "px-3 py-2 text-sm",
        lg:      "px-4 py-2.5 text-base"
      },
      resize: {
        vertical: "resize-y",
        none:     "resize-none",
        both:     "resize"
      },
      autogrow: {
        true  => "field-sizing-content min-h-16 resize-none",
        false => ""
      },
      error: {
        true  => "border-destructive focus:ring-destructive",
        false => ""
      }
    },
    defaults: { size: :default, resize: :vertical, autogrow: false, error: false }
  )

  # `form:` + `field:` render through the form builder's text_area, so the
  # field gets a scoped name like `post[body]` and its value from the model.
  # Without them a plain <textarea> is rendered; pass `name:` and `value:`.
  def initialize(size: :default, rows: 3, resize: :vertical, autogrow: false,
                 label: nil, label_size: :default, label_weight: :medium,
                 hint: nil, required: false, error: nil, disabled: false,
                 value: nil, form: nil, field: nil,
                 class: nil, **html_attrs)
    @form         = form
    @field        = field
    @size         = size
    @rows         = rows
    @resize       = resize
    @autogrow     = autogrow
    @label        = label
    @label_size   = label_size
    @label_weight = label_weight
    @required     = required
    @error        = error
    @disabled     = disabled
    @value        = value
    @user_class   = binding.local_variable_get(:class)
    @html_attrs   = html_attrs
    @wrapper      = UI::FormField.new(label: label, hint: hint, error: error,
                                      required: required, disabled: disabled,
                                      label_size: label_size, label_weight: label_weight,
                                      form: form, field: field)
    @textarea_id  = @html_attrs[:id] || (@wrapper.wrap? ? "ui-textarea-#{SecureRandom.hex(4)}" : nil)
    @html_attrs[:id] = @textarea_id if @textarea_id
    @wrapper.for  = @textarea_id
  end

  attr_reader :value, :wrapper

  def classes
    cn(
      variant_classes(size: @size, resize: @resize, autogrow: @autogrow, error: wrapper.error?),
      @user_class
    )
  end

  def html_options
    opts = @html_attrs.dup
    opts[:rows]           = @rows
    opts[:class]          = classes
    opts[:disabled]       = true if @disabled
    opts[:required]       = true if @required
    opts[:"aria-invalid"] = "true" if wrapper.error?
    opts[:"aria-describedby"] = wrapper.describedby if wrapper.describedby
    opts
  end

  def form_field?
    @form.present? && @field.present?
  end

  # The builder derives the name and value itself.
  def form_field_options
    html_options.except(:name)
  end
end
