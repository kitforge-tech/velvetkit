module Helio
  # The numbers on the Overview, worked out from the customers, so they all
  # agree with each other and with the Customers page.
  class Metrics
    RANGES = { "7d" => 7, "30d" => 30, "90d" => 90 }.freeze

    attr_reader :days, :today

    def initialize(range: "30d", customers: Customer.all, today: Customer::TODAY)
      @days      = RANGES.fetch(range, 30)
      @customers = customers
      @today     = today
    end

    def period = (today - days + 1)..today
    def previous_period = (today - (2 * days) + 1)..(today - days)

    # Each tile: the value now and the value to compare it with. A level
    # (revenue, customers) compares with the start of the period; a flow
    # (sign-ups, cancellations) with the period before.
    def tiles
      [
        { label: "Monthly revenue", value: mrr_on(today), before: mrr_on(today - days), format: :currency, icon: "dollar-sign" },
        { label: "Paying customers", value: paying_on(today), before: paying_on(today - days), format: :number, icon: "users" },
        { label: "New sign-ups", value: signups(period), before: signups(previous_period), format: :number, icon: "user-plus", flow: true },
        { label: "Cancellations", value: cancellations(period), before: cancellations(previous_period), format: :number,
          icon: "user-minus", lower_is_better: true, flow: true }
      ]
    end

    def mrr_on(date) = @customers.sum { |customer| customer.paying_on?(date) ? customer.list_price : 0 }
    def paying_on(date) = @customers.count { |customer| customer.paying_on?(date) }
    def signups(range) = @customers.count { |customer| range.cover?(customer.signed_up_on) }
    def cancellations(range) = @customers.count { |customer| customer.cancelled_between?(range) }

    # Monthly revenue at the end of each of the last twelve months.
    def revenue_by_month
      months = (0..11).map { |back| (today << back).end_of_month }.reverse
      months[-1] = today
      { labels: months.map { |date| date.strftime("%b") }, data: months.map { |date| mrr_on(date) } }
    end

    # Sign-ups in the period: by day for a week or a month, by week for longer.
    def signups_over_period
      step = days > 30 ? 7 : 1
      starts = period.step(step).to_a
      { labels: starts.map { |date| step == 1 ? date.strftime("%-d %b") : "w/c #{date.strftime('%-d %b')}" },
        data: starts.map { |start| signups(start..[ start + step - 1, today ].min) } }
    end

    # Today's revenue split by plan.
    def revenue_by_plan
      plans = Customer::PLANS.keys
      { labels: plans, data: plans.map { |plan| @customers.select { |customer| customer.plan == plan }.sum(&:mrr) } }
    end

    # Paying customers by country: the five biggest, then the rest.
    def customers_by_country
      counts = @customers.select(&:paying?).group_by(&:country).transform_values(&:size).sort_by { |_, count| -count }
      top = counts.first(5)
      rest = counts.drop(5).sum { |_, count| count }
      top + (rest.positive? ? [ [ "Elsewhere", rest ] ] : [])
    end

    def top_customers(limit = 5) = @customers.select(&:paying?).max_by(limit, &:mrr)

    # The latest goings-on: sign-ups, cancellations and failed payments.
    def activity(limit = 6)
      events = @customers.flat_map do |customer|
        list = [ { kind: :signup, date: customer.signed_up_on, customer: customer } ]
        list << { kind: :cancelled, date: customer.last_active_on, customer: customer } if customer.status == "cancelled"
        list << { kind: :past_due, date: today - (customer.id % 5), customer: customer } if customer.status == "past_due"
        list
      end
      events.sort_by { |event| [ event[:date], event[:customer].id ] }.reverse.first(limit)
    end
  end
end
