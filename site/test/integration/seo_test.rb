require "test_helper"

# What search engines and AI crawlers see.
class SeoTest < ActionDispatch::IntegrationTest
  SITE = "https://velvetkit.com"

  test "every page has its own title and description, a canonical URL and share cards" do
    [ root_path, docs_path, doc_path("ai"), components_path, component_path("dialog") ].each do |path|
      get path
      title = css_select("title").text
      description = css_select("meta[name=description]").first["content"]
      assert_operator title.length, :<=, 70, "#{path} title too long: #{title}"
      assert_operator description.length, :>=, 50, "#{path} description too short"
      assert_select "link[rel=canonical][href=?]", "#{SITE}#{path == root_path ? "/" : path}"
      assert_select "meta[property='og:title'][content=?]", title
      assert_select "meta[property='og:description'][content=?]", description
      assert_select "meta[property='og:image'][content=?]", "#{SITE}/og.png"
      assert_select "meta[name='twitter:card'][content=summary_large_image]"
    end
  end

  test "titles differ from page to page" do
    titles = [ root_path, docs_path, doc_path("theming"), components_path, component_path("tabs") ].map { |path| get(path) && css_select("title").text }
    assert_equal titles.uniq, titles
  end

  test "the home page describes the software in JSON-LD" do
    get root_path
    data = css_select("script[type='application/ld+json']").map { |s| JSON.parse(s.text) }
    types = data.map { _1["@type"] }
    assert_includes types, "SoftwareApplication"
    assert_includes types, "WebSite"
  end

  test "a component page is an article with breadcrumbs and a Markdown alternate" do
    get component_path("dialog")
    data = css_select("script[type='application/ld+json']").map { |s| JSON.parse(s.text) }
    assert(data.any? { _1["@type"] == "TechArticle" && _1["headline"] == "Dialog" })
    crumbs = data.find { _1["@type"] == "BreadcrumbList" }
    assert_equal [ "Docs", "Components", "Dialog" ], crumbs["itemListElement"].map { _1["name"] }
    assert_select "link[rel=alternate][type='text/markdown'][href=?]", "#{SITE}#{component_path("dialog", format: :md)}"
  end

  test "sitemap lists every page" do
    get "/sitemap.xml"
    assert_response :success
    assert_equal "application/xml", response.media_type
    locs = Nokogiri::XML(response.body).remove_namespaces!.xpath("//loc").map(&:text)
    assert_includes locs, "#{SITE}/"
    DocsController::PAGES.each_key { |page| assert_includes locs, page == "getting_started" ? "#{SITE}/docs" : "#{SITE}/docs/#{page}" }
    ComponentDoc.names.each { |name| assert_includes locs, "#{SITE}/docs/components/#{name}" }
  end

  test "robots welcomes search and AI crawlers and points at the sitemap and llms.txt" do
    get "/robots.txt"
    assert_response :success
    assert_includes response.body, "Sitemap: #{SITE}/sitemap.xml"
    %w[GPTBot ClaudeBot PerplexityBot Google-Extended].each { |bot| assert_includes response.body, "User-agent: #{bot}" }
    assert_includes response.body, "#{SITE}/llms.txt"
    assert_includes response.body, "Disallow: /demo/"
  end
end
