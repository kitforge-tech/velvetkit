# frozen_string_literal: true

require "securerandom"

# A score out of five stars (or `max:`), shown or chosen.
#
# Shown, it fills to the nearest half star and reads as one image: "Rated 4.5
# out of 5". `show_value: true` prints the number beside the stars and
# `count:` how many ratings it's the average of.
#
#   <%= render(UI::Rating.new(value: 4.5, count: 128, show_value: true)) %>
#
# Given a `name:` (or `form:` and `field:`), it's a field: a radio for each
# half-star, so it posts in 0.5-point steps, resets with the form and needs no
# JavaScript. Arrow keys move between the half-star values. With JavaScript,
# hovering either half previews the score it gives.
#
#   <%= render(UI::Rating.new(name: "review[rating]", legend: "Your rating", required: true)) %>
#
# As with RadioGroup, a `legend:` (and a `hint:` or `error:`) renders it
# through UI::Fieldset, which names the group and shows the model's errors when
# it's bound to a form; `legend: true` uses the attribute's name. Without a
# legend, `label:` is the field's hidden name ("Rating" if not given).
#
# `icon:` draws another icon from the library, such as "heart".
class UI::Rating < UI::Base
  variants(
    base: "inline-flex shrink-0 items-center",
    variants: {
      size: {
        sm:      "gap-0.5 [&_svg]:size-4",
        default: "gap-0.5 [&_svg]:size-5",
        lg:      "gap-1 [&_svg]:size-6"
      }
    },
    defaults: { size: :default }
  )

  # A filled star's colour, and an empty one's.
  ON  = "text-amber-500"
  OFF = "text-muted-foreground/30"

  # A field's star: lit when its own radio or a later one is checked, so the
  # stars up to the chosen one fill without JavaScript. While the pointer is
  # over the stars, the controller marks each one lit or not, which wins.
  STAR = "relative cursor-pointer rounded-sm transition-colors text-muted-foreground/30 " \
         "[input:checked+&]:text-amber-500 [&:has(~input:checked)]:text-amber-500 " \
         "data-[lit=true]:!text-amber-500 data-[lit=false]:!text-muted-foreground/30 " \
         "[input:focus-visible+&]:outline-2 [input:focus-visible+&]:outline-offset-2 [input:focus-visible+&]:outline-ring"
  STAR_HALF_SIZE = { sm: "h-4 w-2", default: "h-5 w-2.5", lg: "h-6 w-3" }.freeze
  STAR_GAP = { sm: "me-0.5", default: "me-0.5", lg: "me-1" }.freeze

  def initialize(value: nil, max: 5, size: :default, icon: "star",
                 show_value: false, count: nil,
                 name: nil, form: nil, field: nil, required: false, disabled: false,
                 label: nil, legend: nil, hint: nil, error: nil,
                 class: nil, **html_attrs)
    @value      = value
    @max        = Integer(max)
    @size       = size
    @icon       = icon
    @show_value = show_value
    @count      = count
    @name       = name
    @form       = form
    @field      = field
    @required   = required
    @disabled   = disabled
    @label      = label
    @legend     = legend
    @hint       = hint
    @error      = error
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  attr_reader :max, :icon

  def form_field? = @form.present? && @field.present?

  # A field when it has a name to post under; otherwise it shows a score.
  def input? = input_name.present?

  def input_name = form_field? ? "#{@form.object_name}[#{@field}]" : @name

  def score
    value = @value
    value = @form.object.public_send(@field) if value.nil? && form_field? && @form.object.respond_to?(@field)
    Float(value, exception: false)&.clamp(0, @max)
  end

  # --- Shown ------------------------------------------------------------------

  # :full, :half or :empty for each star, to the nearest half.
  def fills
    halves = ((score || 0) * 2).round
    (1..@max).map { |star| halves >= star * 2 ? :full : (halves == star * 2 - 1 ? :half : :empty) }
  end

  # "4.5", "4" or "4,5": the score as the page's locale writes it.
  def formatted_score = ActiveSupport::NumberHelper.number_to_rounded(score || 0, precision: 1, strip_insignificant_zeros: true)

  def image_label = t("ui.rating.label", value: formatted_score, max: @max, default: "Rated %{value} out of %{max}")

  def count? = !@count.nil?
  def formatted_count = ActiveSupport::NumberHelper.number_to_delimited(@count)
  def count_label = t("ui.rating.count", count: @count, default: { one: "%{count} rating", other: "%{count} ratings" })
  def show_value? = @show_value

  def display_attrs
    @html_attrs.merge(class: cn("inline-flex items-center gap-1.5 text-sm", @user_class))
  end

  # --- Chosen -----------------------------------------------------------------

  # Twice the selected score, so a half-star radio is an integer step.
  def chosen_steps = score && (score * 2).round

  def group_id = @group_id ||= @html_attrs[:id] || "ui-rating-#{SecureRandom.hex(4)}"
  def option_id(value) = "#{group_id}-#{value}"
  def option_value(step)
    whole, half = step.divmod(2)
    half.zero? ? whole : "#{whole}.5"
  end
  def option_label(value) = t("ui.rating.option", count: value, max: @max, default: "%{count} out of %{max}")
  def required? = @required
  def disabled? = @disabled

  # The legend shows only when given: a bound field that's never been named
  # doesn't grow one when it has an error.
  def fieldset
    @fieldset ||= UI::Fieldset.new(legend: @legend.presence || false, hint: @hint, error: @error,
                                   form: @form, field: @field, required: @required, disabled: @disabled,
                                   role: "radiogroup", aria: group_aria)
  end

  # Without a legend to name it, the field's name is `label:`.
  def group_aria = { label: (@label.presence || t("ui.rating.name", default: "Rating") unless legend_names_it?) }.compact.merge(@html_attrs[:aria] || {})

  # `legend: true` names it only when bound to a form, from the attribute.
  def legend_names_it? = @legend == true ? form_field? : @legend.present?

  # Inside a fieldset, the fieldset has the role and the aria attributes that
  # name and describe the group; the stars' row keeps the rest.
  def stars_attrs
    wrapped = fieldset.wrap?
    attrs = @html_attrs.except(:id, :aria, :data)
    attrs[:role] = "radiogroup" unless wrapped
    attrs[:aria] = group_aria unless wrapped
    attrs[:id] = group_id
    attrs[:class] = cn(variant_classes(size: @size), "w-fit gap-0", @user_class)
    attrs[:data] = { controller: "ui--rating", action: "mouseleave->ui--rating#reset" }.merge(@html_attrs[:data] || {})
    attrs
  end

  def star_classes(step)
    cn(STAR, STAR_HALF_SIZE.fetch(@size), (STAR_GAP.fetch(@size) if step.even?),
       { "cursor-not-allowed opacity-50" => @disabled })
  end

  def star_icon_classes(step) = cn("absolute inset-y-0 flex", step.odd? ? "start-0" : "-start-full")
end
