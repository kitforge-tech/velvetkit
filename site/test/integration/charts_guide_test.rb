require "test_helper"

# The Charts section: its own place in the sidebar, an overview and a page per
# chart type, each example drawn live with its code beside it.
class ChartsGuideTest < ActionDispatch::IntegrationTest
  ChartsController::PAGES.each_key do |page|
    test "#{page} renders with its charts" do
      get ChartsController.path_for(page)
      assert_response :success
      assert_select "h1", ChartsController::PAGES[page].first == "Overview" ? "Charts" : ChartsController::PAGES[page].first
      assert_select "[data-controller='ui--chart'] canvas[role=img]", minimum: 1
    end
  end

  test "the sidebar has a Charts section with every page, and Chart isn't listed again under Components" do
    get charts_path
    nav = css_select("nav[aria-label='Documentation']").first
    sections = nav.css("p").map(&:text)
    assert_operator sections.index("Charts"), :<, sections.index("Components")
    ChartsController::PAGES.each_key { |page| assert nav.at_css("a[href='#{ChartsController.path_for(page)}']"), page }
    assert_nil nav.at_css("a[href='#{component_path('chart')}']")
    assert_select "nav[aria-label='Documentation'] a[aria-current=page][href=?]", charts_path
  end

  test "each example shows the code it draws" do
    get chart_doc_path("stacked_bar")
    assert_select "h3#pinned", "Keeping colours when a series is left out"
    assert_select "code", text: /color: channels\.fetch\(name\)/
  end

  test "each example's numbers are in a Data tab after Code, not under the chart" do
    get chart_doc_path("bar")
    examples = css_select("section:has(> h3)")
    assert_equal 3, examples.size
    examples.each do |example|
      assert_equal %w[Preview Code Data], example.css("[role=tab]").map { _1.text.strip }
      assert_empty example.css("details")
      assert example.at_css("[role=tabpanel] table th[scope=row]")
    end
    assert_select "td", text: "-$1,800.00"
  end

  test "pie and donut pages show each slice's share, and the donut its total" do
    get chart_doc_path("pie")
    assert_select "[data-type=pie] ul li", minimum: 4
    assert_select "th[scope=col]", text: "Share"
    get chart_doc_path("donut")
    assert_match(/"total":"1,000"|"total":"5,000"/, css_select("[data-type=donut]").first["data-ui--chart-config-value"])
  end

  test "the overview's first chart keeps its own Show the data" do
    get charts_path
    assert_select "details summary", text: "Show the data"
  end

  test "the chart component page still exists for its API" do
    get component_path("chart")
    assert_response :success
  end

  test "chart pages are in the sitemap, search and llms.txt" do
    get sitemap_path
    ChartsController::PAGES.each_key { |page| assert_includes response.body, ChartsController.path_for(page) }
    get llms_path
    assert_includes response.body, "## Charts"
    titles = SearchIndex.entries.select { _1.group == "Charts" }.map(&:title)
    assert_equal ChartsController::PAGES.values.map(&:first), titles
  end
end
