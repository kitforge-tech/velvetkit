module AnalyticsHelper
  ANALYTICS_DOMAINS = "velvetkit.com,www.velvetkit.com"
  OUTBOUND_TARGETS = { ApplicationHelper::GITHUB_URL => "github", ApplicationHelper::RUBYGEMS_URL => "rubygems" }.freeze

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

  # The event a code block reports when copied. Each is its own event, not one
  # with a property, so any of them can be a funnel step.
  def copy_event(source)
    case source
    when ApplicationHelper::SETUP_PROMPT then "copy_agent_prompt"
    when /\Agem "velvetkit"/ then "copy_gem"
    when %r{\Abin/rails (g|generate) velvetkit:install} then "copy_install"
    when %r{\Abin/rails (g|generate) velvetkit:add} then "copy_add"
    else "copy_snippet"
    end
  end

  # A link's outbound click, for its data: option. Only for links that open a
  # new tab: on a same-tab link the tracker takes over the click, which skips
  # Turbo and makes the visit wait for the report.
  def outbound_data(target, placement)
    { umami_event: "outbound_click", umami_event_target: target, umami_event_placement: placement }
  end
end
