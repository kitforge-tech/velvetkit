require "test_helper"

class ReleaseNotesTest < ActiveSupport::TestCase
  CHANGELOG = <<~MARKDOWN
    # Changelog

    ## Unreleased

    New components:

    - `Rating`: not out yet.

    ## 0.4.1 — 2026-11-09

    New components:

    - `Slider`: a handle to drag for a value, or two
      for a range.
    - `Skeleton` and `FileField`.

    Changes:

    - `Card` is redesigned.
    - Fix: `Menu` isn't clipped.

    Upgrading an app: re-run `velvetkit:add card`. Cards
    now have 16px of padding.

    ## 0.2.2 — 2026-11-02

    - Fix: icons were missing.
    - The docs site has a guide.
  MARKDOWN

  test "reads each release, newest first, and leaves out Unreleased" do
    releases = ReleaseNotes.parse(CHANGELOG)
    assert_equal %w[0.4.1 0.2.2], releases.map(&:version)
    assert_equal Date.new(2026, 11, 9), releases.first.date
    assert_equal "v0-4-1", releases.first.id
  end

  test "sorts lines into new components, changes, fixes and notes" do
    release = ReleaseNotes.parse(CHANGELOG).first
    assert_equal [ "`Slider`: a handle to drag for a value, or two for a range.", "`Skeleton` and `FileField`." ], release.components
    assert_equal %w[Slider Skeleton FileField], release.component_names
    assert_equal [ "`Slider`: a handle to drag for a value, or two for a range." ], release.descriptions
    assert_equal [ "`Card` is redesigned." ], release.changes
    assert_equal [ "`Menu` isn't clipped." ], release.fixes
    assert_equal [ "Upgrading an app: re-run `velvetkit:add card`. Cards now have 16px of padding." ], release.notes
  end

  test "bullets with no label are changes" do
    release = ReleaseNotes.parse(CHANGELOG).last
    assert_equal [ "The docs site has a guide." ], release.changes
    assert_equal [ "Icons were missing." ], release.fixes
    assert_empty release.components
  end
end
