# frozen_string_literal: true

# UI::Sheet — side-anchored modal panel backed by the native <dialog> element.
#
# Reuses the ui--dialog controller and follows the same compound API as
# UI::Dialog, but anchors the panel to an edge of the viewport instead of
# centering it.
#
# Compound:
#   UI::Sheet
#   UI::Sheet::Trigger  — click-to-open wrapper (inherits from Dialog::Trigger)
#   UI::Sheet::Content  — the <dialog> + fixed panel; inline title / description / footer
class UI::Sheet < UI::Base
  renders_one :trigger, ->(**opts) {
    UI::Sheet::Trigger.new(**opts).tap { |t| t.set_dialog_context(self) }
  }
  renders_one :body, ->(**opts) {
    UI::Sheet::Content.new(**opts).tap { |c| c.set_sheet_context(self) }
  }
  alias_method :with_content, :with_body

  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @id = @html_attrs[:id] || "ui-sheet-#{SecureRandom.hex(4)}"
    @html_attrs.delete(:id)
  end

  attr_reader :id

  def title_id;       "#{@id}-title";       end
  def description_id; "#{@id}-description"; end

  def root_classes
    cn("contents", @user_class)
  end
end
