# frozen_string_literal: true

class UI::Switch < UI::Base
  THUMB_TRANSLATE = {
    sm:      "peer-checked:translate-x-4",
    default: "peer-checked:translate-x-5",
    lg:      "peer-checked:translate-x-6"
  }.freeze

  variants(
    base: "absolute inset-0 rounded-full " \
          "bg-input peer-checked:bg-primary " \
          "transition-all duration-200 " \
          "peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary " \
          "peer-focus:ring-offset-1 ring-offset-background " \
          "peer-disabled:cursor-not-allowed",
    variants: {
      size: {
        sm:      "w-8 h-4",
        default: "w-10 h-5",
        lg:      "w-12 h-6"
      }
    },
    defaults: { size: :default }
  )

  def initialize(name: nil, value: "1", checked: false,
                 label: nil, size: :default,
                 required: false, disabled: false,
                 class: nil, **html_attrs)
    @name       = name
    @value      = value
    @checked    = checked
    @label_text = label
    @size       = size
    @required   = required
    @disabled   = disabled
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @id = @html_attrs[:id] || ("ui-sw-#{SecureRandom.hex(4)}" if @label_text)
    @html_attrs[:id] = @id if @id
  end

  def label;     @label_text; end
  def required?; @required;    end

  # Visually-hidden checkbox. Owns form value, focus, and disabled state.
  # The `peer` class lets sibling spans react to :checked / :focus-visible /
  # :disabled. `sr-only` keeps the native check icon off-screen so the
  # browser's UA-painted tick can never bleed through (which is what shows
  # up when a styled <input type=checkbox> is left in flow).
  def input_options
    opts = @html_attrs.dup
    opts[:type]     = :checkbox
    opts[:role]     = :switch
    opts[:name]     = @name if @name
    opts[:value]    = @value
    opts[:checked]  = true if @checked
    opts[:disabled] = true if @disabled
    opts[:required] = true if @required
    opts[:class]    = "peer sr-only"
    opts
  end

  SIZE_CLASSES = {
    sm:      "w-8 h-4",
    default: "w-10 h-5",
    lg:      "w-12 h-6"
  }.freeze

  def root_classes
    cn(
      "relative inline-flex shrink-0 items-center",
      SIZE_CLASSES[@size]
    )
  end

  def track_classes
    cn(variant_classes(size: @size), @user_class)
  end

  def thumb_classes
    cn(
      "pointer-events-none absolute left-0.5 top-0.5",
      "rounded-full bg-white shadow-sm",
      "transition-transform",
      THUMB_TRANSLATE[@size],
      {
        sm:      "w-3 h-3",
        default: "w-4 h-4",
        lg:      "w-5 h-5"
      }[@size]
    )
  end

  def wrapper_classes
    cn(
      "inline-flex items-center gap-2 select-none cursor-pointer",
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
