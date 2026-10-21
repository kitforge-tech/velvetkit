# frozen_string_literal: true

require "securerandom"

class UI::Input < UI::Base
  variants(
    base: "flex w-full rounded-md border border-input bg-background " \
          "text-foreground " \
          "placeholder:text-muted-foreground " \
          "#{UI::Base::FOCUS_RING} " \
          "disabled:cursor-not-allowed disabled:opacity-50",
    variants: {
      size: {
        sm:      "h-8 px-2.5 py-1 text-xs",
        default: "h-9 px-3 py-2 text-sm",
        lg:      "h-10 px-4 py-2.5 text-base"
      },
      variant: {
        default:    "",
        error:      "border-destructive focus-visible:ring-destructive",
        with_label: ""
      }
    },
    defaults: { size: :default, variant: :default }
  )

  # `form:` + `field:` opt into Rails form-builder rendering (so the input gets
  # a scoped name like `user[password]` and repopulates from the model). Without
  # them a plain <input> is rendered and `name:` passes through html_attrs.
  # Every type gets its own Rails helper rather than text_field with a type:
  # option. Rails' TextField sets options["type"] ||= "text" against the
  # STRING key, so a symbol :type never wins and the field silently renders as
  # a plain text box — which is what date_of_birth was doing: no picker, no
  # validation, and whatever the user typed accepted as a date.
  BUILDER_METHODS = {
    text: :text_field, email: :email_field, password: :password_field,
    number: :number_field, search: :search_field, tel: :telephone_field,
    url: :url_field, date: :date_field, time: :time_field,
    datetime: :datetime_local_field, month: :month_field, week: :week_field,
    color: :color_field, range: :range_field
  }.freeze

  def initialize(type: :text, size: :default, variant: :default,
                 label: nil, label_size: :default, label_weight: :medium,
                 required: false, error: false, disabled: false,
                 form: nil, field: nil,
                 class: nil, **html_attrs)
    @form           = form
    @field          = field
    @type           = type
    @size           = size
    @variant        = variant
    @label          = label
    @label_size     = label_size
    @label_weight   = label_weight
    @required       = required
    @error          = error
    @disabled       = disabled
    @user_class     = binding.local_variable_get(:class)
    @html_attrs     = html_attrs
    @input_id       = @html_attrs[:id] || (render_label? ? "ui-input-#{SecureRandom.hex(4)}" : nil)
    @html_attrs[:id] = @input_id if @input_id
  end

  def classes
    cn(
      variant_classes(size: @size, variant: @variant),
      @user_class
    )
  end

  def html_options
    opts = @html_attrs.dup
    # String key, for the same reason: Rails checks options["type"].
    opts["type"]          = @type
    opts[:class]          = classes
    opts[:disabled]       = true if @disabled
    opts[:required]       = true if @required
    opts[:"aria-invalid"] = "true" if @error
    opts
  end

  def form_field?
    @form.present? && @field.present?
  end

  # The builder derives the name itself, so drop any explicit one.
  def form_field_options
    html_options.except(:name, :type)
  end

  def form_builder_method
    BUILDER_METHODS.fetch(@type.to_sym, :text_field)
  end

  # Labels follow Rails' own convention: bound to a form object, the attribute
  # name supplies the text (via human_attribute_name, so i18n and
  # `activerecord.attributes.*` overrides apply) with no per-call-site string.
  # Pass `label:` to override the text, or `label: false` to opt out entirely.
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
      for: @input_id,
      size: @label_size,
      weight: @label_weight,
      required: @required,
      disabled: @disabled
    )
  end
end
