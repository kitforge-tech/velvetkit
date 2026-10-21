# frozen_string_literal: true

class UI::SidebarPreview < ViewComponent::Preview
  # @label Default
  def default; render_with_template; end

  # @label With Groups
  def with_groups; render_with_template; end

  # @label With Dropdown Header
  def with_dropdown_header; render_with_template; end

  # @label Collapsible
  def collapsible; render_with_template; end
end
