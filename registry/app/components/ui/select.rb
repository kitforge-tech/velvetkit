# frozen_string_literal: true

require "securerandom"

# UI::Select — a dropdown for choosing one value, or several, styled to match the kit.
#
# The visible part is a WAI-ARIA "select-only combobox": a button with
# role=combobox and a floating role=listbox. Focus stays on the button while
# the arrow keys move through the options, as the pattern specifies.
#
# The value lives in a visually hidden native <select>. That keeps everything a
# form already relies on: the field submits under its name, `required` blocks
# submission, form reset works, the form builder binds it, and anything
# listening for `change` on it still hears one. The Stimulus controller only
# mirrors the choice into it.
#
# `searchable: true` adds a search box that filters the list; `multiple: true`
# lets people pick several, posting `name[]` like a native multiple select.
#
# `url:` searches on the server instead, for lists too long to send to the
# page, such as products, customers or suppliers. Opening the list asks
# `GET url?q=` for a starting list, and typing asks again with what was typed,
# a moment after the typing stops. The server answers with JSON, either
# `[{ "value": 7, "label": "Acme Traders" }, ...]` or `[["Acme Traders", 7], ...]`;
# it decides what matches and how many come back. `param:` renames `q`.
# `options:` are what show before then, so pass the current choice, or an edit
# form opens with nothing named:
#
#   <%= render(UI::Select.new(form: f, field: :customer_id, url: customers_search_path,
#                             options: [[@order.customer&.name, @order.customer_id]].reject { _1.first.nil? },
#                             prompt: "Find a customer")) %>
#
#   # app/controllers/customers_controller.rb
#   def search
#     customers = Customer.where("name ILIKE ?", "%#{Customer.sanitize_sql_like(params[:q].to_s)}%").order(:name).limit(20)
#     render json: customers.map { { value: _1.id, label: _1.name } }
#   end
#
# UI::NativeSelect is the browser's own control, for when a phone's system
# picker is the better fit.
#
# Usage:
#   <%= render(UI::Select.new(form: f, field: :plan, label: "Plan",
#                             options: [["Free", "free"], ["Pro", "pro"]],
#                             prompt: "Choose a plan")) %>
class UI::Select < UI::Base
  variants(
    base: "flex w-full items-center justify-between gap-2 rounded-md border border-input bg-background " \
          "text-left text-foreground shadow-xs " \
          "#{UI::Base::FOCUS_RING} " \
          "aria-expanded:ring-2 aria-expanded:ring-primary aria-expanded:ring-offset-1 " \
          "disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-muted",
    variants: {
      size: {
        sm:      "h-8 px-2.5 text-xs",
        default: "h-9 px-3 text-sm",
        lg:      "h-10 px-4 text-base"
      }
    },
    defaults: { size: :default }
  )

  def initialize(name: nil, options: [], selected: nil, prompt: nil,
                 label: nil, hint: nil, size: :default, searchable: false, multiple: false, url: nil, param: "q",
                 required: false, error: nil, disabled: false,
                 form: nil, field: nil,
                 class: nil, **html_attrs)
    @name       = name
    @options    = options
    @selected   = selected
    @prompt     = prompt
    @label      = label
    @size       = size
    @url        = url
    @param      = param
    @searchable = searchable || url.present?
    @multiple   = multiple
    @required   = required
    @error      = error
    @disabled   = disabled
    @form       = form
    @field      = field
    @user_class = binding.local_variable_get(:class)
    @name_attrs = take_accessible_name(html_attrs)
    @html_attrs = html_attrs
    @uid        = SecureRandom.hex(4)
    @wrapper    = UI::FormField.new(label: label, hint: hint, error: error,
                                    required: required, disabled: disabled,
                                    form: form, field: field, for: trigger_id)
  end

  attr_reader :prompt, :size, :wrapper

  # Lays out its own label, so it takes FormField's parts rather than its wrapper.
  delegate :render_label?, :label_text, :label_component, to: :wrapper

  def searchable? = @searchable
  def remote? = @url.present?
  def multiple? = @multiple

  def trigger_id = "ui-select-#{@uid}"
  def listbox_id = "ui-select-#{@uid}-listbox"
  def search_id = "ui-select-#{@uid}-search"
  def option_id(index) = "ui-select-#{@uid}-option-#{index}"

  def trigger_classes
    cn(variant_classes(size: @size),
       { "border-destructive focus:ring-destructive" => wrapper.error? },
       @user_class)
  end

  def trigger_options
    {
      type: "button",
      id: trigger_id,
      class: trigger_classes,
      role: "combobox",
      disabled: @disabled,
      aria: { haspopup: "listbox", expanded: "false", controls: listbox_id, **@name_attrs,
              invalid: ("true" if wrapper.error?), describedby: wrapper.describedby },
      data: { "ui--select-target": "trigger",
              action: "click->ui--select#toggle keydown->ui--select#keydown" }
    }
  end

  def form_field? = @form.present? && @field.present?

  # Accepts [["Label", value], ...] or a plain list of scalars. A prompt
  # becomes a first, empty option, as `include_blank` makes it natively;
  # a multiple select has no "nothing" option, since nothing is unticking.
  def listbox_options
    list = @options.map { |option| option.is_a?(Array) ? option : [ option, option ] }
    prompt.present? && !multiple? ? [ [ prompt, "" ] ] + list : list
  end

  # What the field holds now, as strings: the explicit selection, else the
  # bound attribute, else (single only) whatever a native select shows first.
  def current_values
    value = @selected
    value = @form.object.public_send(@field) if value.nil? && form_field? && @form.object.respond_to?(@field)
    return Array(value).map(&:to_s) unless value.nil?

    multiple? ? [] : [ listbox_options.first&.last.to_s ]
  end

  def selected?(value) = current_values.include?(value.to_s)

  def chosen_labels = listbox_options.select { |_, value| selected?(value) && value.to_s != "" }.map(&:first)

  # A multiple select names up to two choices, then counts them.
  def current_label
    return chosen_labels.first || prompt unless multiple?
    return prompt || t("ui.select.placeholder", default: "Choose…") if chosen_labels.empty?

    chosen_labels.size > 2 ? summary.sub("%{count}", chosen_labels.size.to_s) : chosen_labels.join(", ")
  end

  def placeholder_shown? = chosen_labels.empty?

  # "%{count} selected", left for the controller to fill in as ticks change.
  def summary = t("ui.select.selected", default: "%{count} selected", count: "%{count}")

  def root_data
    data = { controller: "ui--select", "ui--select-multiple-value": multiple?.to_s,
             "ui--select-summary-value": summary,
             "ui--select-placeholder-value": prompt || t("ui.select.placeholder", default: "Choose…") }
    return data unless remote?

    data.merge("ui--select-url-value": @url, "ui--select-param-value": @param)
  end

  # What a fetched option is built from: one rendered here, so it has the same
  # classes as the options the page arrived with.
  def option_classes(value)
    "relative flex cursor-default select-none items-center rounded-sm py-1.5 pr-8 pl-2 #{size == :sm ? "text-xs" : "text-sm"} " \
      "outline-none data-[highlighted]:bg-accent data-[highlighted]:text-accent-foreground aria-selected:font-medium " \
      "#{value.to_s.empty? ? "text-muted-foreground" : ""}"
  end

  # Said while a search is on its way, and when one fails.
  def status_texts
    { "ui--select-searching-value": t("ui.select.searching", default: "Searching…"),
      "ui--select-failed-value": t("ui.select.failed", default: "Couldn't load the results. Try again.") }
  end

  # The hidden native select. Everything the caller passed beyond our own
  # arguments lands here, so ids and change listeners keep working.
  def native_options
    attrs = @html_attrs.dup
    attrs[:class] = "sr-only"
    attrs[:tabindex] = -1
    attrs[:aria] = (attrs[:aria] || {}).merge(hidden: true)
    attrs[:data] = (attrs[:data] || {}).merge("ui--select-target": "native")
    attrs[:required] = true if @required
    attrs[:disabled] = true if @disabled
    attrs[:multiple] = true if multiple?
    attrs[:name] = multiple? ? "#{@name}[]" : @name if @name && !form_field?
    attrs
  end

  # Whether the button has a name for the list to borrow.
  def named? = render_label? || @name_attrs.any?

  def native_choices
    listbox_options.map { |label, value| [ label, value ] }
  end

  private

  # `aria-label` or `aria-labelledby` names what people reach, the visible
  # button. Left in html_attrs it would go on the native select, which is
  # hidden from screen readers, and the button would have no name at all.
  def take_accessible_name(attrs)
    aria = attrs[:aria] = (attrs[:aria] || {}).dup
    { label: attrs.delete(:"aria-label") || aria.delete(:label),
      labelledby: attrs.delete(:"aria-labelledby") || aria.delete(:labelledby) }.compact
  end
end
