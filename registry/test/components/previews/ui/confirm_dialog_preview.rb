# frozen_string_literal: true

# These examples post to /demo/ paths; the docs site stops those requests and
# shows a toast instead, so confirming here changes nothing.
class UI::ConfirmDialogPreview < ViewComponent::Preview
  # @label Destructive
  def destructive; render_with_template; end

  # @label With a Description
  def with_description; render_with_template; end

  # @label On a Link
  def on_link; render_with_template; end

  # @label In a Form
  def in_form; render_with_template; end

  # @label Plain
  def plain; render_with_template; end
end
