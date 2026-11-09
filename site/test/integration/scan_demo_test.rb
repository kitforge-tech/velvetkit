require "test_helper"

# The till behind ScanInput's demo.
class ScanDemoTest < ActionDispatch::IntegrationTest
  test "a known code appends a cart line" do
    post demo_scans_path, params: { code: " 8901030865278 " }, as: :turbo_stream
    assert_response :success
    assert_includes response.body, %(action="append" target="scan-demo-lines")
    assert_includes response.body, "Basmati rice, 1 kg"
    assert_includes response.body, "₹189.00"
    assert_includes response.body, %(action="update" target="scan-demo-status"), "a found item clears the last error"
  end

  test "an unknown code says so" do
    post demo_scans_path, params: { code: "123" }, as: :turbo_stream
    assert_includes response.body, %(action="update" target="scan-demo-status")
    assert_includes response.body, "No item with the code 123"
  end
end
