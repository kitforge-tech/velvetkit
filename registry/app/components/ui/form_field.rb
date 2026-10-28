# frozen_string_literal: true

require "securerandom"

# A label, a control, a hint and an error message, wired together: the label
# points at the control, and the control is described by the hint and error.
#
# Input, Textarea, NativeSelect and Select render through it, so they take
# `hint:` and `error:` directly. Wrap any other control yourself and spread
# `field.control_attributes` onto it:
#
#   <%= render(UI::FormField.new(label: "Colour", hint: "Used for your avatar")) do |field| %>
#     <%= tag.input(type: "color", name: "colour", **field.control_attributes) %>
#   <% end %>
#
# `error:` takes a message, or `true` to mark the control invalid without one.
# Bound to a form (`form:` + `field:`), the model's errors on that attribute
# are the message (for `team_id`, the `team` association's too, where
# belongs_to puts "must exist"), and the attribute's human name is the label
# (`label:` overrides it, `label: false` opts out). Nothing to show means no
# wrapper: just the control.
class UI::FormField < UI::Base
  def initialize(label: nil, hint: nil, error: nil, required: false, disabled: false,
                 label_size: :default, label_weight: :medium,
                 form: nil, field: nil, for: nil,
                 class: nil, **html_attrs)
    @label        = label
    @hint         = hint
    @error        = error
    @required     = required
    @disabled     = disabled
    @label_size   = label_size
    @label_weight = label_weight
    @form         = form
    @field        = field
    @for          = binding.local_variable_get(:for)
    @user_class   = binding.local_variable_get(:class)
    @html_attrs   = html_attrs
  end

  attr_reader :hint
  attr_writer :for

  def form_field? = @form.present? && @field.present?

  def wrap? = render_label? || hint.present? || error_message.present?

  # The id the label points at and the messages hang off. Controls set their
  # own (`for:`); otherwise one is made the first time it's asked for.
  def control_id
    @for ||= "ui-field-#{SecureRandom.hex(4)}"
  end

  def hint_id = "#{control_id}-hint"
  def error_id = "#{control_id}-error"

  def error_message
    return @error if @error.is_a?(String)
    return if @error == false || !form_field?

    errors = @form.object.respond_to?(:errors) ? @form.object.errors : nil
    return unless errors

    attributes = [ @field.to_sym, @field.to_s.delete_suffix("_id").to_sym ].uniq
    attributes.flat_map { |attribute| errors.full_messages_for(attribute) }.uniq.to_sentence.presence
  end

  def error? = @error == true || error_message.present?

  def describedby
    [ (hint_id if hint.present?), (error_id if error_message.present?) ].compact.join(" ").presence
  end

  # Spread onto a control you render yourself.
  def control_attributes
    { id: control_id, "aria-describedby": describedby, "aria-invalid": ("true" if error?) }.compact
  end

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
    UI::Label.new(for: control_id, size: @label_size, weight: @label_weight,
                  required: @required, disabled: @disabled)
  end

  def classes
    cn("flex flex-col gap-2 w-full", @user_class)
  end
end
