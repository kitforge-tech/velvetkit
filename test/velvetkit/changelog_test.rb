# frozen_string_literal: true

require "minitest/autorun"
require "velvetkit"

# The docs site's release notes are read from CHANGELOG.md, so a component
# with no entry there never shows as released. Each new component gets a line
# under "## Unreleased" > "New components:" in the PR that adds it (AGENTS.md).
class Velvetkit::ChangelogTest < Minitest::Test
  CHANGELOG = File.expand_path("../../CHANGELOG.md", __dir__)

  def test_every_component_is_in_the_changelog
    named = File.read(CHANGELOG).scan(/`([A-Z]\w*)`/).flatten
    missing = (Velvetkit.registry.names - [ "base" ]).map { |name| name.split("_").map(&:capitalize).join }.reject { named.include?(_1) }

    assert_empty missing, "Add these to CHANGELOG.md under ## Unreleased > New components:"
  end

  def test_every_release_heading_has_a_version_and_a_date
    headings = File.read(CHANGELOG).scan(/^## (.+)$/).flatten - [ "Unreleased" ]

    assert_empty headings.grep_v(/\A\d+\.\d+\.\d+(\.\w+)? — \d{4}-\d{2}-\d{2}\z/),
                 "Write release headings as ## 0.4.1 — 2026-11-09, or the releases page skips them"
  end

  # The page reads each date with Date.iso8601, which raises on a day that
  # doesn't exist (2026-11-31), taking the page down with it.
  def test_every_release_date_is_a_real_day
    dates = File.read(CHANGELOG).scan(/^## \S+ — (\d{4}-\d{2}-\d{2})$/).flatten
    invalid = dates.reject { Date.iso8601(_1) rescue false }

    assert_empty invalid, "Not real dates"
  end
end
