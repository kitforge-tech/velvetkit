require "test_helper"

# The endpoint behind the File Field's direct-upload example: it answers
# Active Storage's two requests the same way a real app does, and keeps nothing.
class FileFieldDemoTest < ActionDispatch::IntegrationTest
  test "asking for a blob returns a signed id and where to send the file" do
    post rails_direct_uploads_path, params: { blob: { filename: "mug.jpg", byte_size: 2048, content_type: "image/jpeg" } }, as: :json
    assert_response :success
    body = response.parsed_body
    assert_match(/\Ademo-/, body["signed_id"])
    assert_includes body.dig("direct_upload", "url"), "/demo/uploads/"
    assert_equal "image/jpeg", body.dig("direct_upload", "headers", "Content-Type")
  end

  test "sending the file is accepted and thrown away" do
    put demo_upload_path("abc123"), params: "bytes", headers: { "Content-Type" => "image/jpeg" }
    assert_response :no_content
  end

  test "files over 10 MB are turned away" do
    post rails_direct_uploads_path, params: { blob: { filename: "huge.jpg", byte_size: 11.megabytes, content_type: "image/jpeg" } }, as: :json
    assert_response :content_too_large
  end
end
