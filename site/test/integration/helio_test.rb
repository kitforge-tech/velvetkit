require "test_helper"

# Helio, the example dashboard mounted at /examples/dashboard.
class HelioTest < ActionDispatch::IntegrationTest
  test "the overview shows the numbers, charts, what needs attention, top customers and activity" do
    get "/examples/dashboard"
    assert_response :success
    assert_select "title", /\AOverview · Helio/
    assert_select "aside#helio-sidebar a[aria-current=page]", text: "Overview"
    assert_select "main ul li", minimum: 4
    assert_select "main", /Monthly revenue/
    assert_select "[data-slot=chart]", 3
    assert_select "[data-slot=chart] details", count: 0
    assert_select "section[aria-labelledby=attention-heading] li a[href^='/examples/dashboard/customers/']", minimum: 1
    assert_select "table[aria-label='Top customers by monthly revenue'] tbody tr", 5
    assert_select "meta[name=robots]", count: 0
  end

  test "customers filter, sort and page, with a box on each row" do
    get "/examples/dashboard/customers"
    assert_response :success
    assert_select "nav[aria-label=Views] a[aria-current=page]", /All/
    assert_select "table[aria-label=Customers] tbody tr", 20
    assert_select "tbody [data-selection=item][form=bulk]", 20
    assert_select "th[aria-sort=descending]", /MRR/
    assert_select "nav[aria-label=Pages] a[href=?]", "/examples/dashboard/customers?page=2"

    get "/examples/dashboard/customers", params: { view: "trialing", plan: "Team", sort: "company", dir: "asc" }
    trialing = Helio::Customer.all.select { |c| c.status == "trialing" && c.plan == "Team" }
    assert_select "table tbody tr", [ trialing.size, 20 ].min
    assert_equal trialing.map(&:company).sort.first, css_select("table tbody tr a").first.text
    assert_select "th[aria-sort=ascending]", /Customer/

    get "/examples/dashboard/customers", params: { q: "zzzz" }
    assert_select "td", /No customers match/
  end

  test "a customer's page, and changes kept for this visitor" do
    customer = Helio::Customer.all.find { |c| c.status == "trialing" }
    get "/examples/dashboard/customers/#{customer.id}"
    assert_select "h1", customer.company
    assert_select "[role=tablist] [role=tab]", 3

    patch "/examples/dashboard/customers/#{customer.id}", params: { do: "extend_trial" }
    follow_redirect!
    assert_match "14 more days", response.body
    assert_match (customer.trial_ends_on + 14).strftime("%-d %b %Y"), response.body

    post "/examples/dashboard/customers/bulk", params: { do: "cancel", ids: [ customer.id ] }
    get "/examples/dashboard/customers/#{customer.id}"
    assert_select "h1 + span, h1 ~ *", /Cancelled/

    post "/examples/dashboard/customers/#{customer.id}/notes", params: { text: "Asked about annual billing." }
    follow_redirect!
    assert_select "li", /Asked about annual billing/

    get "/examples/dashboard/customers/9999"
    assert_response :not_found
  end

  test "customers export as CSV, the chosen ones or all that match" do
    first, second = Helio::Customer.all.first(2)
    get "/examples/dashboard/customers.csv", params: { ids: [ first.id, second.id ] }
    lines = response.body.lines
    assert_equal "text/csv", response.media_type
    assert_equal 3, lines.size
    assert_match first.company, response.body
  end

  test "the period picker changes the comparison, and a chosen period isn't indexed" do
    get "/examples/dashboard", params: { range: "90d" }
    assert_select "input[name=range][value='90d'][checked]"
    assert_select "main", /vs previous 90 days/
    assert_select "main", /Last 90 days, by week/
    assert_select "meta[name=robots][content='noindex, follow']"

    get "/examples/dashboard", params: { range: "bogus" }
    assert_select "input[name=range][value='30d'][checked]"
  end

  test "the metrics agree with the customers" do
    metrics = Helio::Metrics.new
    paying = Helio::Customer.all.select { |customer| customer.paying_on?(metrics.today) }
    assert_equal paying.sum(&:list_price), metrics.mrr_on(metrics.today)
    assert_equal paying.size, metrics.tiles.second[:value]
    assert_equal metrics.revenue_by_month[:data].last, metrics.mrr_on(metrics.today)
    assert_equal Helio::Customer.all.sum(&:mrr), metrics.revenue_by_plan[:data].sum
  end
end
