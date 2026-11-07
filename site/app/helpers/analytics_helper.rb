module AnalyticsHelper
  ANALYTICS_DOMAINS = "velvetkit.com,www.velvetkit.com"

  # The tracker, when the app is told where it lives. async rather than defer:
  # a deferred script holds up DOMContentLoaded, and Stimulus with it, so a slow
  # analytics server would freeze the page. Queries and hashes stay out because
  # the tracker also watches replaceState, which the table of contents and the
  # namespace playground use.
  def analytics_tag
    script_url, website_id = Rails.configuration.x.then { [ _1.umami_script_url, _1.umami_website_id ] }
    return unless script_url && website_id

    tag.script(src: script_url, async: true,
               data: { website_id: website_id, domains: ANALYTICS_DOMAINS, exclude_search: "true", exclude_hash: "true" })
  end
end
