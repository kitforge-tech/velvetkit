require "test_helper"

# Helio, the example dashboard mounted at /examples/dashboard.
class HelioTest < ActionDispatch::IntegrationTest
  test "the overview shows the stat cards, charts, top customers and activity" do
    get "/examples/dashboard"
    assert_response :success
    assert_select "title", /\AOverview · Helio/
    assert_select "aside#helio-sidebar a[aria-current=page]", text: "Overview"
    assert_select "main ul li", minimum: 4
    assert_select "main", /Monthly revenue/
    assert_select "[data-slot=chart]", 3
    assert_select "table[aria-label='Top customers by monthly revenue'] tbody tr", 5
    assert_select "meta[name=robots]", count: 0
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
