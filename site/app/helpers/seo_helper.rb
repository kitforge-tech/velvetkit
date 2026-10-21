# Titles, descriptions, canonical links, share cards and structured data:
# what search engines and AI crawlers read about a page.
module SeoHelper
  DEFAULT_DESCRIPTION = "Accessible ViewComponent UI components for Rails, copied into your app one at a time " \
                        "under your own namespace, with docs your AI agent reads.".freeze

  def site_url(path = "/")
    "#{Rails.configuration.x.site_url}#{path}"
  end

  def page_title
    [ content_for(:title), "VelvetKit" ].compact.join(" · ")
  end

  def page_description
    content_for(:description).presence || DEFAULT_DESCRIPTION
  end

  def canonical_url
    site_url(request.path)
  end

  def json_ld(data)
    tag.script(data.merge("@context" => "https://schema.org").to_json.html_safe, type: "application/ld+json") # rubocop:disable Rails/OutputSafety -- to_json escapes <, > and &
  end

  # A docs or component page: an article, with its breadcrumb trail.
  def article_structured_data(title, crumbs)
    safe_join([
      json_ld("@type" => "TechArticle", "headline" => title, "description" => page_description, "url" => canonical_url,
              "isPartOf" => { "@type" => "WebSite", "name" => "VelvetKit", "url" => site_url },
              "author" => { "@type" => "Organization", "name" => "KitForge", "url" => "https://kitforge.tech" }),
      json_ld("@type" => "BreadcrumbList",
              "itemListElement" => crumbs.each_with_index.map { |(name, path), index|
                { "@type" => "ListItem", "position" => index + 1, "name" => name, "item" => site_url(path) }
              })
    ])
  end
end
