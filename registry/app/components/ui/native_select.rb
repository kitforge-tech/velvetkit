# frozen_string_literal: true

require "securerandom"

# UI::NativeSelect — the browser's own <select>, styled closed.
#
# UI::Select is the styled dropdown. Reach for this one when the platform
# control is the better fit: on a phone it opens the system picker, which is
# easier to use with a thumb than any custom list, and it needs no JavaScript.
# The open list is drawn by the operating system, so it can't be themed.
#
# Usage:
#   <%= render(UI::NativeSelect.new(form: f, field: :section_id, label: "Section",
#                                   options: @sections.map { [_1.full_name, _1.id] },
#                                   prompt: "Choose a section")) %>
class UI::NativeSelect < UI::Base
  variants(
    base: "flex w-full appearance-none rounded-md border border-input bg-background " \
          "text-foreground " \
          "#{UI::Base::FOCUS_RING} " \
          "disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-muted!",
    variants: {
      size: {
        sm:      "h-8 pl-2.5 pr-8 py-1 text-xs",
        default: "h-9 pl-3 pr-9 py-2 text-sm",
        lg:      "h-10 pl-4 pr-10 py-2.5 text-base"
      }
    },
    defaults: { size: :default }
  )

  def initialize(name: nil, options: [], selected: nil, prompt: nil,
                 label: nil, size: :default,
                 required: false, error: false, disabled: false,
                 form: nil, field: nil,
                 class: nil, **html_attrs)
    @name       = name
    @options    = options
    @selected   = selected
    @prompt     = prompt
    @label      = label
    @size       = size
    @required   = required
    @error      = error
    @disabled   = disabled
    @form       = form
    @field      = field
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @select_id  = @html_attrs[:id] || (render_label? ? "ui-native-select-#{SecureRandom.hex(4)}" : nil)
    @html_attrs[:id] = @select_id if @select_id
  end

  attr_reader :options, :prompt

  def classes
    cn(variant_classes(size: @size),
       { "border-destructive focus-visible:ring-destructive" => @error },
       @user_class)
  end

  def form_field? = @form.present? && @field.present?

  # Same convention as UI::Input: bound to a form object the attribute name
  # supplies the label; `label:` overrides, `label: false` opts out.
  def render_label?
    return false if @label == false

    @label.present? || form_field?
  end

  def label_text
    return nil unless render_label?
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
    UI::Label.new(for: @select_id, required: @required, disabled: @disabled)
  end

  def select_options
    opts = @html_attrs.dup
    opts[:class] = classes
    opts[:name] = @name if @name
    opts[:disabled] = true if @disabled
    opts[:required] = true if @required
    opts[:"aria-invalid"] = "true" if @error
    opts
  end

  # The form builder derives the name and id itself, so they are dropped here
  # to avoid overriding the scoped name with a bare one.
  def form_select_options = select_options.except(:name)

  # Accepts [["Label", value], ...] or a plain list of scalars.
  def normalized_options
    options.map { |option| option.is_a?(Array) ? option : [ option, option ] }
  end

  def selected?(value) = @selected.present? && @selected.to_s == value.to_s
end
