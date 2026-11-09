# frozen_string_literal: true

require "minitest/autorun"
require "rake"
require "velvetkit"
load File.expand_path("../../rakelib/changelog.rake", __dir__)

# rake changelog:release[X.Y.Z], which turns Unreleased into a release.
class Velvetkit::ChangelogReleaseTest < Minitest::Test
  DATE = Date.new(2026, 11, 20)

  CHANGELOG = <<~MARKDOWN
    # Changelog

    ## Unreleased

    New components:

    - `Rating`: stars to pick a score.

    ## 0.4.2 — 2026-11-09

    - Fix: something.
  MARKDOWN

  def cut(version, changelog = CHANGELOG) = ChangelogRelease.cut(changelog, version, DATE)

  def test_unreleased_becomes_the_release_under_a_new_empty_unreleased
    assert_equal <<~MARKDOWN, cut("0.5.0")
      # Changelog

      ## Unreleased

      ## 0.5.0 — 2026-11-20

      New components:

      - `Rating`: stars to pick a score.

      ## 0.4.2 — 2026-11-09

      - Fix: something.
    MARKDOWN
  end

  def test_a_prerelease_is_a_version_too
    assert_includes cut("0.5.0.beta"), "## 0.5.0.beta — 2026-11-20"
  end

  def test_refuses_what_would_make_a_bad_release
    { "v0.5.0" => /isn't a gem version/, "0.4.2" => /already in/, "0.4.1" => /isn't newer than 0.4.2/ }.each do |version, message|
      assert_match message, assert_raises(ArgumentError) { cut(version) }.message
    end
    assert_match(/Nothing under/, assert_raises(ArgumentError) { cut("0.5.0", CHANGELOG.sub(/^New components:.*?score\.\n/m, "")) }.message)
    assert_match(/no ## Unreleased/, assert_raises(ArgumentError) { cut("0.5.0", CHANGELOG.sub("## Unreleased", "## Next")) }.message)
  end

  def test_dates_the_releases_page_in_the_sitemap
    lastmod = %("/docs/forms": '2026-10-29'\n"/docs/releases": '2026-11-09'\n)
    assert_equal %("/docs/forms": '2026-10-29'\n"/docs/releases": '2026-11-20'\n), ChangelogRelease.touch_lastmod(lastmod, DATE)
  end

  def test_the_real_changelog_and_lastmod_are_in_the_shape_it_expects
    root = File.expand_path("../..", __dir__)
    assert_match(/^## Unreleased$/, File.read(File.join(root, "CHANGELOG.md")))
    assert_match ChangelogRelease::LASTMOD, File.read(File.join(root, "site/config/lastmod.yml"))
  end
end
