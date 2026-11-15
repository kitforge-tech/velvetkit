module Helio
  module DashboardHelper
    # The sidebar's pages. Customers opens onto its saved views.
    def nav_items
      [
        { text: "Overview", icon: "layout-dashboard", href: root_path },
        { text: "Customers", icon: "users", href: customers_path,
          views: CustomersController::VIEWS.except("all").map { |view, label| { text: label, href: customers_path(view:), view: } } }
      ]
    end

    def nav_active?(href) = href == root_path ? current_page?(href) : request.path.start_with?(href)

    # A link to the customers list with some of its filters changed, keeping
    # the rest, and back to the first page.
    def customers_link(**changes)
      current = params.permit(:view, :q, :plan, :sort, :dir).to_h.symbolize_keys
      current.delete(:plan) if current[:plan] == "all"
      customers_path(current.merge(changes).compact_blank)
    end

    # A column header's link: sorts by it, or flips it if it's sorted already.
    def sort_href(column)
      dir = @sort == column && @dir == "desc" ? "asc" : "desc"
      dir = "asc" if @sort != column && column == "company"
      customers_link(sort: column, dir:)
    end

    def sorted(column) = (@dir.to_sym if @sort == column)

    def last_active(date)
      days = (Customer::TODAY - date).to_i
      return "Today" if days.zero?
      return "Yesterday" if days == 1
      return "#{days} days ago" if days < 30

      date.strftime("%-d %b %Y")
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
