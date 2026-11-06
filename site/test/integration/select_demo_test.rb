require "test_helper"

# The endpoint behind the Select's server-search demo: matches only, at most 20.
class SelectDemoTest < ActionDispatch::IntegrationTest
  test "searching returns the matching customers as value and label" do
    get demo_customers_path(q: "rao")
    results = response.parsed_body
    assert_not_empty results
    assert results.all? { _1["label"].downcase.include?("rao") && _1["value"].is_a?(Integer) }
  end

  test "an empty search returns the first page, not everyone" do
    get demo_customers_path(q: "")
    assert_equal 20, response.parsed_body.size
  end

  test "the select page shows the live demo" do
    get component_path("select")
    assert_select "#demo"
    assert_select "[data-ui--select-url-value='#{demo_customers_path}']", 2
  end
end
