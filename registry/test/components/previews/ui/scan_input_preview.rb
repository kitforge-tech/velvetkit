# frozen_string_literal: true

class UI::ScanInputPreview < ViewComponent::Preview
  # @label Playground
  # @param label text
  # @param placeholder text
  # @param size select { choices: [sm, default, lg] }
  # @param suffix select { choices: [enter, tab] } "The key the scanner ends a code with"
  # @param keyboard toggle "Off keeps a phone's on-screen keyboard down"
  # @param capture toggle "Keys typed anywhere on the page go into the field"
  # @param disabled toggle
  # @param hint text
  # @param error text
  def playground(label: "Scan an item", placeholder: "", size: :default, suffix: :enter, keyboard: true,
                 capture: false, disabled: false, hint: "", error: "")
    render_with_template(locals: { options: {
      label: label.presence, placeholder: placeholder.presence, size: size.to_sym, suffix: suffix.to_sym,
      keyboard: keyboard, capture: capture, disabled: disabled, hint: hint.presence, error: error.presence
    } })
  end

  # @label Library Checkout
  def library_checkout; render_with_template; end

  # @label Stock Count, Scanning Anywhere on the Page
  def stock_count; render_with_template; end

  # @label Ticket Check-in on a Handheld
  def ticket_check_in; render_with_template; end

  # @label Till, Sent to the Server
  def till; render_with_template; end
end
