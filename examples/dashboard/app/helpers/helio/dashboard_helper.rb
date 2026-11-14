module Helio
  module DashboardHelper
    # The sidebar's pages. Reports and Settings are placeholders until they exist.
    def nav_groups
      [
        { label: "Workspace", items: [
          { text: "Overview", icon: "layout-dashboard", href: root_path },
          { text: "Customers", icon: "users", href: customers_path },
          { text: "Reports", icon: "chart-column", href: "#" }
        ] },
        { label: "Account", items: [
          { text: "Settings", icon: "settings", href: "#" },
          { text: "Help", icon: "life-buoy", href: "#" }
        ] }
      ]
    end

    def money(amount) = number_to_currency(amount, precision: 0)

    # "+12.4%" and whether that's good news, for a tile's change badge.
    def change(value, before, lower_is_better: false)
      return [ "New", true ] if before.zero? && value.positive?
      return [ "0%", true ] if before.zero?

      percent = (value - before) * 100.0 / before
      [ "#{'+' if percent.positive?}#{number_with_precision(percent, precision: 1)}%", lower_is_better ? percent <= 0 : percent >= 0 ]
    end

    STATUS_BADGES = { "active" => :success, "trialing" => :secondary, "past_due" => :warning, "cancelled" => :outline }.freeze

    def status_badge(status)
      render(UI::Badge.new(variant: STATUS_BADGES.fetch(status, :outline), class: "rounded-full")) { status.humanize }
    end
  end
end
