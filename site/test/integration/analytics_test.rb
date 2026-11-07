require "test_helper"

class AnalyticsTest < ActionDispatch::IntegrationTest
  SCRIPT = "https://analytics.example.com/script.js"

  def with_umami(script_url: SCRIPT, website_id: "site-id")
    config = Rails.configuration.x
    before = [ config.umami_script_url, config.umami_website_id ]
    config.umami_script_url, config.umami_website_id = script_url, website_id
    yield
  ensure
    config.umami_script_url, config.umami_website_id = before
  end

  test "no tracker unless configured" do
    with_umami(script_url: nil, website_id: nil) { get root_path }
    assert_select "script[data-website-id]", count: 0
  end

  test "no tracker with only half the configuration" do
    with_umami(website_id: nil) { get root_path }
    assert_select "script[data-website-id]", count: 0
    with_umami(script_url: nil) { get root_path }
    assert_select "script[data-website-id]", count: 0
  end

  test "the tracker can't hold the page up, and ignores queries, hashes and other hosts" do
    with_umami { get root_path }
    assert_select "head script[src='#{SCRIPT}'][data-website-id='site-id']", count: 1 do |tags|
      tag = tags.first
      assert tag.has_attribute?("async")
      assert_not tag.has_attribute?("defer")
      assert_equal "true", tag["data-exclude-search"]
      assert_equal "true", tag["data-exclude-hash"]
      assert_equal "velvetkit.com,www.velvetkit.com", tag["data-domains"]
    end
  end

  test "code blocks name what copying them means" do
    get root_path
    assert_select "[data-clipboard-track-value=copy_gem]", minimum: 1
    assert_select "[data-clipboard-track-value=copy_install]", minimum: 1
    assert_select "[data-clipboard-track-value=copy_add]", minimum: 1

    get doc_path("ai")
    assert_select "[data-clipboard-track-value=copy_agent_prompt]", count: 1
    assert_select "[data-clipboard-track-value=copy_snippet]", minimum: 1

    get component_path("dialog")
    assert_select "[data-clipboard-track-value=copy_add]", minimum: 1
    assert_select "[data-clipboard-track-value=copy_markdown]", count: 1
  end

  test "copy_event reads the source" do
    helper = ApplicationController.helpers
    assert_equal "copy_install", helper.copy_event("bin/rails g velvetkit:install")
    assert_equal "copy_install", helper.copy_event("bin/rails generate velvetkit:install --icons=phosphor")
    assert_equal "copy_add", helper.copy_event("bin/rails generate velvetkit:add dialog")
    assert_equal "copy_gem", helper.copy_event(%(gem "velvetkit", group: :development))
    assert_equal "copy_agent_prompt", helper.copy_event(ApplicationHelper::SETUP_PROMPT)
    assert_equal "copy_snippet", helper.copy_event("bin/rails generate velvetkit:icons rocket")
    assert_equal "copy_snippet", helper.copy_event("bundle install")
  end
end
