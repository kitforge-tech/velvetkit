require "test_helper"

# Every page renders. The component pages render the registry's preview
# templates live, so this also catches an example that no longer works with
# the component it shows.
class PagesTest < ActionDispatch::IntegrationTest
  test "home" do
    get root_path
    assert_response :success
    assert_select "h1", /Ship Rails UI/
  end

  DocsController::PAGES.each_key do |page|
    test "#{page} guide" do
      get doc_path(page)
      assert_response :success
    end
  end

  test "namespace playground rewrites real files" do
    get doc_path("namespacing", namespace: "Admin")
    assert_response :success
    assert_select ".vk-code", text: /class Admin::Dialog < Admin::Base/
  end

  test "namespace playground explains a bad name" do
    get doc_path("namespacing", namespace: "not valid")
    assert_select "[role=alert], .text-destructive", minimum: 1
  end

  test "components index lists every component" do
    get components_path
    assert_response :success
    ComponentDoc.all.each { |component| assert_includes response.body, component_path(component) }
  end

  ComponentDoc.names.each do |name|
    test "#{name} page" do
      get component_path(name)
      assert_response :success
    end
  end

  test "data grid demo rows page, sort and filter" do
    get demo_rows_path, params: { startRow: 0, endRow: 5,
                                  sortModel: [ { colId: "id", sort: "desc" } ].to_json,
                                  filterModel: { plan: { filterType: "text", filter: "team" } }.to_json }
    body = response.parsed_body
    assert_equal 5, body["rows"].size
    assert body["rows"].all? { |row| row["plan"] == "Team" }
    assert_operator body["rows"].first["id"], :>, body["rows"].last["id"]
  end

  test "favicons and the manifest are linked and served" do
    get root_path
    assert_select "link[rel=icon][href='/favicon.ico']"
    assert_select "link[rel=apple-touch-icon][href='/apple-touch-icon.png']"

    get pwa_manifest_path(format: :json)
    assert_equal "VelvetKit", response.parsed_body["name"]
    response.parsed_body["icons"].each { |icon| assert Rails.public_path.join(icon["src"].delete_prefix("/")).exist?, icon["src"] }
  end

  test "code blocks are highlighted by language" do
    get component_path("button")
    assert_select ".vk-code span.cp", minimum: 1 # ERB tags in the examples
    assert_select ".vk-code span.no", text: "UI", minimum: 1

    get docs_path
    assert_select ".vk-code span.s2", text: '"velvetkit"' # the Gemfile line is Ruby
  end
end
