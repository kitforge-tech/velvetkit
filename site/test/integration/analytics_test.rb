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
end
