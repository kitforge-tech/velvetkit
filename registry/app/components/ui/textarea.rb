# frozen_string_literal: true

require "securerandom"

# A multi-line text field, with the same label, required, error and
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
                 required: false, error: false, disabled: false,
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
    @textarea_id  = @html_attrs[:id] || (render_label? ? "ui-textarea-#{SecureRandom.hex(4)}" : nil)
    @html_attrs[:id] = @textarea_id if @textarea_id
  end

  attr_reader :value

  def classes
    cn(
      variant_classes(size: @size, resize: @resize, autogrow: @autogrow, error: @error),
      @user_class
    )
  end

  def html_options
    opts = @html_attrs.dup
    opts[:rows]           = @rows
    opts[:class]          = classes
    opts[:disabled]       = true if @disabled
    opts[:required]       = true if @required
    opts[:"aria-invalid"] = "true" if @error
    opts
  end

  def form_field?
    @form.present? && @field.present?
  end

  # The builder derives the name and value itself.
  def form_field_options
    html_options.except(:name)
  end

  # As UI::Input: bound to a form object, the attribute name supplies the
  # label. Pass `label:` to override it, or `label: false` to opt out.
  def render_label?
    return false if @label == false

    @label.present? || form_field?
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
    UI::Label.new(
      for: @textarea_id,
      size: @label_size,
      weight: @label_weight,
      required: @required,
      disabled: @disabled
    )
  end
end
