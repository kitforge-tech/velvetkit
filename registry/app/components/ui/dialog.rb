# frozen_string_literal: true

# UI::Dialog — modal dialog backed by the native <dialog> element + showModal().
#
# Why native <dialog>:
#   - Browser owns the modal mode, focus trap, ESC handling, and inert
#     background. We do not reimplement any of that in JS.
#   - The Stimulus controller only opens, closes, and dismisses on backdrop
#     click. Everything else is delegated to the platform.
#
# Compound:
#   UI::Dialog
#   UI::Dialog::Trigger    — wraps any element with a click action
#   UI::Dialog::Content    — the <dialog> box; exposes with_title /
#                            with_description / with_footer block helpers
#                            (no further sub-component classes).
class UI::Dialog < UI::Base
  renders_one :trigger, ->(**opts) {
    UI::Dialog::Trigger.new(**opts).tap { |t| t.set_dialog_context(self) }
  }
  renders_one :body, ->(**opts) {
    UI::Dialog::Content.new(**opts).tap { |c| c.set_dialog_context(self) }
  }
  alias_method :with_content, :with_body

  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @id = @html_attrs[:id] || "ui-dialog-#{SecureRandom.hex(4)}"
    @html_attrs.delete(:id)
  end

  attr_reader :id

  def title_id;       "#{@id}-title";       end
  def description_id; "#{@id}-description"; end

  def root_classes
    cn("contents", @user_class)
  end
end
