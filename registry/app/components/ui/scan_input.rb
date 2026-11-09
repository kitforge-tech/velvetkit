# frozen_string_literal: true

require "securerandom"

# A field for a barcode or QR scanner, or a code typed by hand. A scanner is
# a keyboard that types very fast and presses Enter; this field is ready for
# it: focused, with nothing in the way, and sending each code as it comes.
#
#   <%= form_with url: cart_items_path do |f| %>
#     <%= render(UI::ScanInput.new(name: "code", label: "Scan an item")) %>
#   <% end %>
#
# Enter submits the form with the code and empties the field for the next
# one. A code that arrives while the last is still being sent (a Turbo form
# submission) waits its turn, so two quick scans are two requests, not one
# lost. Before that it fires `ui--scan-input:scan` with `{ code }`; call
# `preventDefault()` on it to handle the code in JavaScript instead.
# `submit: false` never submits, and only fires the event.
#
# It's focused on load and when it comes back in a Turbo update, and
# `keep_focus:` (on by default) takes focus back when it falls to the page,
# after a click on empty space or a dialog closing; moving to another field
# or button is left alone. `capture: true` goes further: keys typed with
# nothing focused go into the field, for a page that's only for scanning.
#
# `keyboard: false` keeps the on-screen keyboard down, for handheld scanners
# with a phone's screen. `suffix: :tab` is for scanners set to end a code
# with Tab instead of Enter. Spelling, capitals and autofill are off, since a
# code isn't a word.
#
# Each scan briefly rings the field, so the person scanning can see it took.
# It takes the same label, hint, error, size and form-builder options as
# UI::Input.
class UI::ScanInput < UI::Base
  SIZES = {
    sm:      "h-8 [&>input]:h-full [&>input]:text-xs",
    default: "h-9",
    lg:      "h-12 [&>input]:h-full [&>input]:text-base"
  }.freeze

  SUFFIXES = %i[enter tab].freeze

  # The ring after a scan, over the group's own focus ring.
  SCANNED = "data-scanned:border-emerald-500 data-scanned:ring-3 data-scanned:ring-emerald-500/30 " \
            "motion-reduce:transition-none"

  def initialize(name: nil, value: nil, form: nil, field: nil, label: nil, hint: nil, error: nil, placeholder: nil,
                 submit: true, clear: true, keep_focus: true, capture: false, keyboard: true, suffix: :enter,
                 autofocus: true, size: :default, required: false, disabled: false, class: nil, **html_attrs)
    @name       = name
    @value      = value
    @form       = form
    @field      = field
    @placeholder = placeholder
    @submit     = submit
    @clear      = clear
    @keep_focus = keep_focus
    @capture    = capture
    @keyboard   = keyboard
    @suffix     = SUFFIXES.include?(suffix&.to_sym) ? suffix.to_sym : :enter
    @autofocus  = autofocus
    @size       = SIZES.key?(size.to_sym) ? size.to_sym : :default
    @required   = required
    @disabled   = disabled
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @input_id   = html_attrs.delete(:id) || "ui-scan-input-#{SecureRandom.hex(4)}"
    @wrapper    = UI::FormField.new(label: label, hint: hint, error: error, required: required, disabled: disabled,
                                    form: form, field: field, for: @input_id)
  end

  attr_reader :wrapper

  def group_component
    UI::InputGroup.new(
      class: cn(SCANNED, SIZES[@size], @user_class),
      data: { controller: "ui--scan-input", disabled: (true if @disabled),
              "ui--scan-input-submit-value": @submit, "ui--scan-input-clear-value": @clear,
              "ui--scan-input-keep-focus-value": @keep_focus, "ui--scan-input-capture-value": @capture,
              "ui--scan-input-suffix-value": @suffix }.compact
    )
  end

  def field_options
    data = @html_attrs[:data] || {}
    action = [ "keydown->ui--scan-input#key", data[:action] ].compact.join(" ")
    { type: :text, form: @form, field: @field, name: (@name unless @form && @field), value: @value, label: false,
      placeholder: @placeholder || t("ui.scan_input.placeholder", default: "Scan or type a code"),
      required: @required, disabled: @disabled, error: wrapper.error?, "aria-describedby": wrapper.describedby,
      autocomplete: "off", autocapitalize: "off", autocorrect: "off", spellcheck: false, enterkeyhint: "go",
      inputmode: ("none" unless @keyboard), autofocus: (true if @autofocus && !@disabled),
      **@html_attrs, id: @input_id, data: data.merge("ui--scan-input-target": "field", action: action) }.compact
  end
end
