# frozen_string_literal: true

require "minitest/autorun"
require "rake"
require "velvetkit"
load File.expand_path("../../rakelib/changelog.rake", __dir__)

# rake changelog:release[X.Y.Z], which writes a release's notes from git.
class Velvetkit::ChangelogReleaseTest < Minitest::Test
  DATE = Date.new(2026, 11, 20)
  ROOT = File.expand_path("../..", __dir__)

  CATALOG = {
    "card" => { "description" => "A surface for one thing." },
    "rating" => { "description" => "Stars to pick a score, or to show one." },
    "select" => { "description" => "A styled dropdown." }
  }.freeze

  def pr(number, branch, title, *files) = ChangelogRelease::Pr.new(number: number, branch: branch, title: title, files: files)

  def notes(prs: [], unreleased: "", previous: %w[card select]) =
    ChangelogRelease.notes(components: CATALOG, previous: previous, prs: prs, unreleased: unreleased)

  def test_new_components_come_from_the_catalog
    assert_equal "New components:\n\n- `Rating`: stars to pick a score, or to show one.", notes
  end

  def test_each_pr_that_changes_the_kit_is_a_line_in_its_own_title
    prs = [ pr(80, "fix/select-name", "Select: aria-label names the visible button", "registry/app/components/ui/select.rb"),
            pr(78, "feat/card-refresh", "Card: redesigned, with an image", "registry/app/components/ui/card.rb"),
            pr(82, "feat/add-bundles", "feat(generators): add wires lazy bundles", "lib/velvetkit/generators/add.rb") ]

    assert_equal <<~MARKDOWN.strip, notes(prs: prs, previous: CATALOG.keys)
      Changes:

      - `Card`: redesigned, with an image (#78)
      - Add wires lazy bundles (#82)
      - Fix: `Select`: aria-label names the visible button (#80)
    MARKDOWN
  end

  def test_leaves_out_prs_that_dont_change_what_an_app_gets
    prs = [ pr(73, "feat/site-search", "Docs site search", "site/app/views/layouts/_search.html.erb"),
            pr(79, "docs/changelog-0.4.2", "Changelog: 0.4.2", "CHANGELOG.md", "registry/config/locales/velvetkit.en.yml"),
            pr(90, "feat/rating", "New Comp: Rating", "registry/app/components/ui/rating.rb", "registry/components.yml") ]

    assert_equal "New components:\n\n- `Rating`: stars to pick a score, or to show one.", notes(prs: prs)
  end

  def test_keeps_what_was_written_by_hand_and_doesnt_repeat_it
    unreleased = <<~MARKDOWN
      - Fix: `Select` puts `aria-label` on its visible button. (#80)

      Upgrading an app: re-run `velvetkit:add select`, then
      `velvetkit:add card`.
    MARKDOWN
    prs = [ pr(80, "fix/select-name", "Select: aria-label names the visible button", "registry/app/components/ui/select.rb") ]

    assert_equal <<~MARKDOWN.strip, notes(prs: prs, unreleased: unreleased, previous: CATALOG.keys)
      Changes:

      - Fix: `Select` puts `aria-label` on its visible button. (#80)

      Upgrading an app: re-run `velvetkit:add select`, then
      `velvetkit:add card`.
    MARKDOWN
  end

  def test_long_lines_wrap_like_the_rest_of_the_changelog
    long = pr(81, "feat/card", "Card: #{"a soft ring and a tinted footer band " * 3}", "registry/app/components/ui/card.rb")
    assert(notes(prs: [ long ], previous: CATALOG.keys).lines.all? { _1.chomp.length <= ChangelogRelease::WIDTH })
  end

  def test_cut_puts_the_notes_under_a_new_empty_unreleased
    changelog = "# Changelog\n\n## Unreleased\n\n- Fix: something.\n\n## 0.4.2 — 2026-11-09\n\n- Old.\n"
    assert_equal "# Changelog\n\n## Unreleased\n\n## 0.5.0 — 2026-11-20\n\nNEW\n\n## 0.4.2 — 2026-11-09\n\n- Old.\n",
                 ChangelogRelease.cut(changelog, "0.5.0", DATE, "NEW")
  end

  def test_cut_refuses_what_would_make_a_bad_release
    changelog = "## Unreleased\n\n## 0.4.2 — 2026-11-09\n"
    { "v0.5.0" => /isn't a gem version/, "0.4.2" => /already in/, "0.4.1" => /isn't newer than 0.4.2/ }.each do |version, message|
      assert_match message, assert_raises(ArgumentError) { ChangelogRelease.cut(changelog, version, DATE, "NEW") }.message
    end
    assert_match(/Nothing to release/, assert_raises(ArgumentError) { ChangelogRelease.cut(changelog, "0.5.0", DATE, "") }.message)
    assert_match(/no ## Unreleased/, assert_raises(ArgumentError) { ChangelogRelease.cut("## 0.4.2 — 2026-11-09\n", "0.5.0", DATE, "NEW") }.message)
  end

  def test_dates_the_releases_page_in_the_sitemap
    lastmod = %("/docs/forms": '2026-10-29'\n"/docs/releases": '2026-11-09'\n)
    assert_equal %("/docs/forms": '2026-10-29'\n"/docs/releases": '2026-11-20'\n), ChangelogRelease.touch_lastmod(lastmod, DATE)
  end

  # Against the real history: 0.4.1 added these three, through PRs #74 to #76.
  def test_reads_a_real_release_from_git
    skip "needs the v0.4.0 and v0.4.1 tags (git fetch --tags)" unless system("git", "-C", ROOT, "rev-parse", "-q", "--verify", "v0.4.1^{commit}", out: File::NULL)

    catalog = ->(ref) { ChangelogRelease.catalog(ChangelogRelease.git(ROOT, "show", "#{ref}:registry/components.yml")) }
    prs = ChangelogRelease.prs(ROOT, from: "v0.4.0", to: "v0.4.1")
    notes = ChangelogRelease.notes(components: catalog.("v0.4.1"), previous: catalog.("v0.4.0").keys, prs: prs, unreleased: "")

    assert_equal [ 74, 75, 76, 77 ], prs.map(&:number).sort
    assert_equal %w[MoneyInput ScanInput Slider], notes.scan(/^- `(\w+)`/).flatten
    refute_includes notes, "Changes:"
  end

  def test_the_real_changelog_and_lastmod_are_in_the_shape_it_expects
    assert_match(/^## Unreleased$/, File.read(File.join(ROOT, "CHANGELOG.md")))
    assert_match ChangelogRelease::LASTMOD, File.read(File.join(ROOT, "site/config/lastmod.yml"))
  end
end
