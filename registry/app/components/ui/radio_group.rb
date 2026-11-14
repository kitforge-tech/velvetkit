# frozen_string_literal: true

# A set of radio buttons. Give it a `legend:` (and a `hint:` or `error:`) and
# it renders through UI::Fieldset: a <fieldset role="radiogroup"> named by its
# legend, around the radios. Bind it to a form builder with `form:` and
# `field:`, and the model's errors on that attribute show on their own;
# `legend: true` then uses the attribute's name.
class UI::RadioGroup < UI::Base
  renders_many :items, ->(value:, **opts) {
    item = UI::RadioGroup::Item.new(value: value, **opts)
    item.set_group_context(self)
    item
  }

  def initialize(name: nil, value: nil, size: :default,
                 required: false, disabled: false,
                 legend: nil, hint: nil, error: nil,
                 form: nil, field: nil,
                 class: nil, **html_attrs)
    @name       = name
    @value      = value
    @size       = size
    @required   = required
    @disabled   = disabled
    @legend     = legend
    @hint       = hint
    @error      = error
    @form       = form
    @field      = field
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("flex flex-col gap-2", @user_class)
  end

  def group_id
    @html_attrs[:id] || "ui-rg-#{SecureRandom.hex(4)}"
  end

  # The legend shows only when given: a bound group that's never been named
  # doesn't grow one when it has an error.
  def fieldset
    @fieldset ||= UI::Fieldset.new(legend: @legend.presence || false, hint: @hint, error: @error,
                                   form: @form, field: @field,
                                   required: @required, disabled: @disabled,
                                   role: "radiogroup", aria: @html_attrs[:aria])
  end

  # Inside a fieldset, the fieldset has the role and the aria attributes that
  # name and describe the group; the radios' container keeps the rest.
  def group_attrs
    wrapped = fieldset.wrap?
    attrs = wrapped ? @html_attrs.except(:id, :aria) : @html_attrs.except(:id)
    { role: ("radiogroup" unless wrapped), id: group_id, class: classes, **attrs }
  end

  def form_field? = @form.present? && @field.present?

  def required?;  @required; end
  def disabled?;  @disabled; end
  def size;       @size;     end

  def name
    form_field? ? "#{@form.object_name}[#{@field}]" : @name
  end

  # As a string, since each item compares it with its own value as one.
  def value
    value = @value
    value = @form.object.public_send(@field) if value.nil? && form_field? && @form.object.respond_to?(@field)
    value&.to_s
  end
end
