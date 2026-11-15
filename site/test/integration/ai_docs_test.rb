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

  test "llms.txt links every guide and chart page as Markdown" do
    get llms_path
    DocsController::PAGES.each_key do |page|
      assert_includes response.body, page == "getting_started" ? docs_url(format: :md) : doc_url(page, format: :md)
    end
    ChartsController::PAGES.each_key do |page|
      assert_includes response.body, page == "overview" ? charts_url(format: :md) : chart_doc_url(page, format: :md)
    end
  end

  test "llms-full.txt ends with upgrading and the newest minor version's release notes" do
    get llms_full_path
    assert_includes response.body, "## Upgrading"
    assert_includes response.body, "### From 0.4 to 0.5"
    assert_match(/^### #{Regexp.escape(ReleaseNotes.all.first.version)} — /, response.body)
    refute_match(/^### Unreleased/, response.body)
  end

  # Each page turned into Markdown: its title, its prose and code, but not
  # the navigation, buttons or playgrounds around them.
  { docs: [ "getting_started" ], doc: DocsController::PAGES.keys.excluding("getting_started", "releases") }.each do |route, pages|
    pages.each do |page|
      test "the #{page} guide as Markdown" do
        get route == :docs ? docs_path(format: :md) : doc_path(page, format: :md)
        assert_response :success
        assert_equal "text/markdown", response.media_type
        assert response.body.start_with?("# #{DocsController::PAGES[page]}\n")
        refute_match(/Ask AI|Copy code|Previous|On this page/, response.body)
        prose = response.body.gsub(/^ *```.*?^ *```/m, "").gsub(/`[^`]*`/, "")
        refute_match(/<[a-z]|^#+ *$|^\d+\. \d/, prose)
      end
    end
  end

  ChartsController::PAGES.each_key do |page|
    test "the #{page} chart page as Markdown, with each example's code" do
      get ChartsController.path_for(page).then { "#{_1}.md" }
      assert_response :success
      assert response.body.start_with?("# ")
      assert_includes response.body, "```erb\n<%= render(UI::Chart.new(" if page != "overview"
    end
  end

  test "the upgrading guide's steps and code survive as Markdown" do
    get doc_path("upgrading", format: :md)
    assert_includes response.body, "1. **Commit first**"
    assert_includes response.body, "```shell\n   bin/rails generate velvetkit:add base"
    assert_includes response.body, %(```erb\n   <%= render(UI::Sidebar.new(id: "app-sidebar", state: :collapsed)) do |sidebar| %>)
  end

  test "release notes as Markdown are CHANGELOG.md's releases" do
    get doc_path("releases", format: :md)
    assert_response :success
    assert response.body.start_with?("# VelvetKit release notes")
    assert_includes response.body, doc_url("upgrading", format: :md)
    assert_includes response.body, "## #{ReleaseNotes.all.first.version} — "
    refute_includes response.body, "## Unreleased"
  end

  test "a docs page in any other format is not found" do
    get "/docs/theming.txt"
    assert_response :not_found
  end

  test "the upgrading and release notes pages offer their Markdown to copy and open in an assistant" do
    { "upgrading" => "## From 0.4 to 0.5", "releases" => "# VelvetKit release notes" }.each do |page, text|
      get doc_path(page)
      assert_select "[data-clipboard-target=source]", text: /#{Regexp.escape(text)}/
      assert_select "a[href=?]", doc_path(page, format: :md)
      assert_select "a[href^='https://claude.ai/new?q=']"
      assert_select "link[rel=alternate][type='text/markdown'][href$=?]", doc_path(page, format: :md)
    end
  end

  test "lookbook is mounted on the registry previews" do
    get "/lookbook"
    assert_response :success
  end
end
