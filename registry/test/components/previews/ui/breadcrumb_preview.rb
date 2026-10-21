# frozen_string_literal: true

class UI::BreadcrumbPreview < ViewComponent::Preview
  # @label Playground
  # @param size select { choices: [sm, md] }
  def playground(size: :sm)
    render(UI::Breadcrumb.new(size: size.to_sym)) do |bc|
      bc.with_item(href: "#", text: "Workspace")
      bc.with_item(href: "#", text: "Website")
      bc.with_item(href: "#", text: "Issues")
      bc.with_item(href: "#", text: "#1234")
    end
  end

  # @label Default (sm)
  def default; render_with_template; end

  # @label Medium (md)
  def medium; render_with_template; end

  # @label With Avatar
  def with_avatar; render_with_template; end

  # @label Long Path
  def long_path; render_with_template; end

  # @label Collapsed — middle (default)
  # Auto-ellipsis with collapse_at: :middle. Keeps first and last segments.
  def collapsed_middle
    render(UI::Breadcrumb.new(max_items: 3, collapse_at: :middle)) do |bc|
      bc.with_item(href: "#", text: "Handbook")
      bc.with_item(href: "#", text: "Docs")
      bc.with_item(href: "#", text: "API")
      bc.with_item(href: "#", text: "Platform")
      bc.with_item(href: "#", text: "Cloud providers")
    end
  end

  # @label Collapsed — start
  # Auto-ellipsis with collapse_at: :start. Keeps the last segments.
  def collapsed_start
    render(UI::Breadcrumb.new(max_items: 3, collapse_at: :start)) do |bc|
      bc.with_item(href: "#", text: "Learn")
      bc.with_item(href: "#", text: "Tutorials")
      bc.with_item(href: "#", text: "Get Started")
      bc.with_item(href: "#", text: "Components")
      bc.with_item(href: "#", text: "Breadcrumb")
    end
  end

  # @label Collapsed — end
  # Auto-ellipsis with collapse_at: :end. Keeps the first segments.
  def collapsed_end
    render(UI::Breadcrumb.new(max_items: 3, collapse_at: :end)) do |bc|
      bc.with_item(href: "#", text: "Home")
      bc.with_item(href: "#", text: "Settings")
      bc.with_item(href: "#", text: "Account")
      bc.with_item(href: "#", text: "Billing")
      bc.with_item(href: "#", text: "Invoices")
    end
  end

  # @label Collapsed (legacy explicit ellipsis)
  # Manual ellipsis slot (deprecated — use max_items + collapse_at instead)
  def collapsed; render_with_template; end
end
