require "test_helper"

# The endpoint behind the Command's server-search demo.
class CommandDemoTest < ActionDispatch::IntegrationTest
  test "searching returns a few matching customers, each with where to go and a group" do
    get demo_search_path(q: "rao")
    results = response.parsed_body
    assert_includes 1..6, results.size
    results.each do |result|
      assert_includes result["label"].downcase, "rao"
      assert_match(/\A#customer-\d+\z/, result["href"])
      assert_match(/\ACustomer #\d+\z/, result["description"])
      assert_equal "Customers", result["group"]
    end
  end

  test "an empty search returns nothing, since the palette lists its own items" do
    get demo_search_path(q: " ")
    assert_equal [], response.parsed_body
  end

  test "the select's endpoint is unchanged" do
    get demo_customers_path(q: "rao")
    assert response.parsed_body.all? { _1.keys.sort == %w[label value] }
  end
end
