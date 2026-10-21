# frozen_string_literal: true

class UI::RadioGroup::Item < UI::Base
  variants(
    base: "peer appearance-none shrink-0 rounded-full border border-input bg-background " \
          "transition-all " \
          "checked:bg-primary checked:border-primary " \
          "focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-1 " \
          "ring-offset-background",
    variants: {
      size: {
        sm:      "w-3.5 h-3.5",
        default: "w-4 h-4",
        lg:      "w-5 h-5"
      }
    },
    defaults: { size: :default }
  )

  DOT_SIZE = { sm: "w-2 h-2", default: "w-2.5 h-2.5", lg: "w-3.5 h-3.5" }.freeze

  def initialize(value:, label: nil, disabled: false, size: nil,
                 class: nil, **html_attrs)
    @value      = value
    @label_text = label
    @disabled   = disabled
    @size       = size
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @id = @html_attrs[:id] || "ui-rg-item-#{SecureRandom.hex(4)}"
    @html_attrs[:id] = @id
  end

  attr_reader :value

  def label;     @label_text; end
  def id;        @id;          end
  def disabled?; @disabled;    end
  def required?; @group_required; end

  def input_options
    opts = @html_attrs.dup
    opts[:type]    = :radio
    opts[:value]   = @value
    opts[:checked] = true if @group_value == @value.to_s
    opts[:disabled] = true if @disabled || @group_disabled
    opts[:required] = true if @group_required
    opts[:name]     = @group_name
    opts[:class]    = classes
    opts
  end

  def classes
    cn(variant_classes(size: @size || :default), @user_class)
  end

  def dot_classes
    cn(
      "pointer-events-none absolute inset-0 flex items-center justify-center",
      "opacity-0 peer-checked:opacity-100 transition-opacity"
    )
  end

  def dot_size_class
    DOT_SIZE[@size || :default]
  end

  def wrapper_classes
    cn(
      "inline-flex items-center gap-2 select-none",
      { "cursor-not-allowed opacity-60" => @disabled || @group_disabled }
    )
  end

  def label_text_classes
    cn(
      "text-sm leading-none",
      { "text-muted-foreground" => @disabled || @group_disabled }
    )
  end

  def checked?
    @group_value == @value.to_s
  end

  def set_group_context(group)
    @group_name     = group.name
    @group_value    = group.value
    @group_required = group.required?
    @group_disabled = group.disabled?
    @size         ||= group.size
  end

  def render?
    @group_name.present?
  end
end
