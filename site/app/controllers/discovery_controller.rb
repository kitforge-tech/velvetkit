# sitemap.xml and robots.txt: how search engines and AI crawlers find their
# way round the site. Both are built from the routes, so a new page or
# component is listed without anyone remembering to add it.
class DiscoveryController < ApplicationController
  include SeoHelper

  # Crawlers that build AI answers and assistants, named so their welcome is
  # explicit rather than implied by a catch-all.
  AI_CRAWLERS = %w[GPTBot OAI-SearchBot ChatGPT-User ClaudeBot Claude-Web anthropic-ai PerplexityBot
                   Google-Extended Applebot-Extended CCBot Bytespider meta-externalagent].freeze

  def sitemap
    pages = [ root_path, docs_path ] +
            DocsController::PAGES.keys.excluding("getting_started").map { |page| doc_path(page) } +
            [ components_path ] + ComponentDoc.names.map { |name| component_path(name) }

    xml = pages.map { |path| "  <url><loc>#{ERB::Util.html_escape(site_url(path))}</loc></url>" }.join("\n")
    render xml: %(<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n#{xml}\n</urlset>\n)
  end

  def robots
    rules = ([ "*" ] + AI_CRAWLERS).map { |bot| "User-agent: #{bot}\nAllow: /\nDisallow: /demo/\n" }
    render plain: <<~TXT, content_type: "text/plain"
      # VelvetKit welcomes search engines and AI crawlers.
      # For AI: a plain-text index of the docs is at #{site_url("/llms.txt")}
      # and everything in one file at #{site_url("/llms-full.txt")}.

      #{rules.join("\n")}
      Sitemap: #{site_url("/sitemap.xml")}
    TXT
  end
end
