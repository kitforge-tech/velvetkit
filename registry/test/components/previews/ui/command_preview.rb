# frozen_string_literal: true

class UI::CommandPreview < ViewComponent::Preview
  # @label Playground
  # @param dialog toggle "Opened with ⌘K, over the page"
  # @param placeholder text
  def playground(dialog: false, placeholder: "Type a command or search…")
    render_with_template(locals: { dialog: dialog, placeholder: placeholder.presence })
  end

  # @label ⌘K, Over the Page
  def dialog; render_with_template; end

  # @label Searching the Server
  def server_search; render_with_template; end

  # @label On the Page
  def inline; render_with_template; end

  # @label Shortcuts That Work, Palette Closed or Open
  def shortcuts; render_with_template; end

  # @label Finding a Product at a Till
  def till; render_with_template; end
end
