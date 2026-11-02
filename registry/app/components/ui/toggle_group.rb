# frozen_string_literal: true

# A row of buttons where one is chosen (like radios) or several are
# (`multiple: true`, like checkboxes). Each item is a real radio or checkbox
# input inside its label, so it posts with the form under `name`, resets with
# it, and needs no JavaScript: arrow keys move between radios and Space ticks a
# checkbox. Bind it to a form builder with `form:` and `field:`.
#
# A multiple group also posts an empty `name[]` value, so unticking every item
# still sends the field, the way Rails' collection_check_boxes does.
#
# `variant: :default` is a segmented control on a muted track; `:outline`
# joins bordered buttons. Give the group a `label:` (its accessible name), and
# give an icon-only item a `label:` too, which becomes its hidden text and
# tooltip. Listen for `change` on the group to act as soon as the choice changes.
class UI::ToggleGroup < UI::Base
  variants(
    base: "inline-flex w-fit items-center",
    variants: {
      variant: {
        default: "gap-1 rounded-lg bg-muted p-1 text-muted-foreground",
        outline: "rounded-md border border-input bg-background shadow-xs " \
                 "divide-x divide-input overflow-hidden"
      }
    },
    defaults: { variant: :default }
  )

  renders_many :items, ->(value:, **opts) {
    UI::ToggleGroup::Item.new(value: value, **opts).tap { |item| item.set_group_context(self) }
  }

  def initialize(name: nil, value: nil, multiple: false, variant: :default, size: :default,
                 label: nil, form: nil, field: nil, required: false, disabled: false,
                 class: nil, **html_attrs)
    @name       = name
    @value      = value
    @multiple   = multiple
    @variant    = variant
    @size       = size
    @label      = label
    @form       = form
    @field      = field
    @required   = required
    @disabled   = disabled
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  attr_reader :variant, :size

  def multiple? = @multiple
  def disabled? = @disabled
  def required? = @required && !multiple?

  def form_field? = @form.present? && @field.present?

  def input_name
    base = form_field? ? "#{@form.object_name}[#{@field}]" : @name
    return if base.blank?

    multiple? ? "#{base}[]" : base
  end

  def selected
    value = @value
    value = @form.object.public_send(@field) if value.nil? && form_field? && @form.object.respond_to?(@field)
    Array(value).map(&:to_s)
  end

  def root_attrs
    attrs = @html_attrs.except(:data, :aria)
    attrs[:role] = multiple? ? "group" : "radiogroup"
    attrs[:class] = cn(variant_classes(variant: @variant), @user_class)
    attrs[:data] = { slot: "toggle-group", variant: @variant }.merge(@html_attrs[:data] || {})
    attrs[:aria] = { label: @label.presence }.compact.merge(@html_attrs[:aria] || {})
    attrs
  end
end
