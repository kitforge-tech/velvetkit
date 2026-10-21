require "test_helper"

# The docs as agents read them.
class AiDocsTest < ActionDispatch::IntegrationTest
  test "llms.txt indexes the docs and every component's Markdown" do
    get llms_path
    assert_response :success
    assert_equal "text/plain", response.media_type
    assert response.body.start_with?("# VelvetKit")
    ComponentDoc.names.each { |name| assert_includes response.body, component_url(name, format: :md) }
  end

  test "llms-full.txt has setup, the rules and every component" do
    get llms_full_path
    assert_response :success
    assert_includes response.body, "## Setting up an app"
    assert_includes response.body, "## Rules"
    ComponentDoc.all.each { |component| assert_includes response.body, "## #{component.title} (`#{component.class_name}`)" }
  end

  test "a component as Markdown" do
    get component_path("dialog", format: :md)
    assert_response :success
    assert_equal "text/markdown", response.media_type
    assert_includes response.body, "UI::Dialog.new("
    assert_includes response.body, "```erb"
  end

  test "component pages offer their Markdown to copy" do
    get component_path("tabs")
    assert_select "[data-clipboard-target=source]", text: /## Tabs/
    assert_select "a[href=?]", component_path("tabs", format: :md)
  end

  test "lookbook is mounted on the registry previews" do
    get "/lookbook"
    assert_response :success
  end
end
