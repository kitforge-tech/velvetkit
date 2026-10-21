# frozen_string_literal: true

class UI::Checkbox < UI::Base
  ICON_SIZE_FOR_SIZE = { sm: :xs, default: :xs, lg: :sm }.freeze

  variants(
    base: "peer appearance-none shrink-0 border border-input bg-background " \
          "transition-colors " \
          "checked:bg-primary checked:border-primary " \
          "focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-1 " \
          "ring-offset-background",
    variants: {
      size: {
        sm:      "w-3.5 h-3.5 rounded-[3px]",
        default: "w-4 h-4 rounded-[4px]",
        lg:      "w-5 h-5 rounded-[5px]"
      }
    },
    defaults: { size: :default }
  )

  def initialize(name: nil, value: "1", unchecked_value: "0", checked: false,
                 label: nil, size: :default,
                 form: nil, field: nil,
                 required: false, error: false, disabled: false,
                 class: nil, **html_attrs)
    @form            = form
    @field           = field
    @name            = name
    @value           = value
    @unchecked_value = unchecked_value
    @checked         = checked
    @label_text      = label
    @size       = size
    @required   = required
    @error      = error
    @disabled   = disabled
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @id = @html_attrs[:id] || ("ui-cb-#{SecureRandom.hex(4)}" if label?)
    @html_attrs[:id] = @id if @id
  end

  def form_field?
    @form.present? && @field.present?
  end

  # Same convention as UI::Input: bound to a form object the attribute name
  # supplies the label text (via human_attribute_name, so i18n applies);
  # `label:` overrides it and `label: false` opts out.
  def label?
    return false if @label_text == false

    @label_text.present? || form_field?
  end

  def label
    return nil unless label?
    return @label_text if @label_text.is_a?(String) && @label_text.present?
    return nil unless form_field?

    object = @form.object
    if object.respond_to?(:class) && object.class.respond_to?(:human_attribute_name)
      object.class.human_attribute_name(@field)
    else
      @field.to_s.humanize
    end
  end

  # Rails' check_box also emits the companion hidden field, so an unchecked box
  # still submits its unchecked value.
  def form_check_box
    @form.check_box(@field, form_input_options, @value, @unchecked_value)
  end

  def form_input_options
    input_options.except(:type, :name, :value, :checked)
  end
  def required?; @required;    end
  def icon_size; ICON_SIZE_FOR_SIZE.fetch(@size); end

  def input_options
    opts = @html_attrs.dup
    opts[:type]    = :checkbox
    opts[:name]    = @name if @name
    opts[:value]   = @value
    opts[:checked] = true if @checked
    opts[:disabled] = true if @disabled
    opts[:required] = true if @required
    opts[:"aria-invalid"] = "true" if @error
    opts[:class]   = classes
    # Add accessible name when no visual label is present
    if !label? && opts[:"aria-label"].blank?
      opts[:"aria-label"] = accessible_name
    end
    opts
  end

  def accessible_name
    # Derive accessible name from name attribute or use default
    return "Checkbox" if @name.blank?

    # Convert "user[terms]" to "User terms"
    @name.to_s.gsub(/[\[\]_]/, " ").gsub(/\s+/, " ").strip.titleize
  end

  def classes
    cn(
      variant_classes(size: @size),
      { "border-destructive aria-invalid:focus:ring-destructive" => @error },
      @user_class
    )
  end

  def overlay_classes
    "pointer-events-none absolute inset-0 flex items-center justify-center " \
    "text-primary-foreground opacity-0 peer-checked:opacity-100 transition-opacity"
  end

  def wrapper_classes
    cn(
      "inline-flex items-center gap-2 select-none",
      { "cursor-not-allowed opacity-60" => @disabled }
    )
  end

  def label_text_classes
    cn(
      "text-sm leading-none",
      { "text-muted-foreground" => @disabled }
    )
  end
end
