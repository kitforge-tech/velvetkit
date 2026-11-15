require "test_helper"

class ReleasesHelperTest < ActionView::TestCase
  test "a version links to its own notes, without reading the changelog" do
    assert_equal "/docs/releases#v0-4-1", release_notes_path("0.4.1")
    assert_equal "/docs/releases#v0-1-0-beta", release_notes_path("0.1.0.beta")
  end

  test "a component chip links to the component's page" do
    render html: release_component_chip("MoneyInput")
    assert_select "a[href='/docs/components/money_input']", text: "Money input"
  end

  test "a component the kit no longer has is a chip without a link" do
    render html: release_component_chip("Lightbox")
    assert_select "a", count: 0
    assert_includes rendered, "Lightbox"
  end

  test "an upgrade note's lead-in becomes its title" do
    assert_equal [ "Upgrading an app", "Re-run `velvetkit:add card`." ], release_note_parts("Upgrading an app: re-run `velvetkit:add card`.")
    assert_equal [ nil, "Something else." ], release_note_parts("Something else.")
  end

  test "a pull request number links to it on GitHub" do
    render html: release_text("`Card` is redesigned (#78), in #4D1A7F")
    assert_select "a[href='https://github.com/kitforge-tech/velvetkit/pull/78']", text: "#78"
    assert_select "a", count: 2
  end

  test "class names in a line link to their component, other code stays code" do
    render html: release_text("`Select` takes `url:`")
    assert_select "a[href='/docs/components/select'] code", text: "Select"
    assert_select "code", text: "url:"
    assert_select "a code", count: 1
  end

  test "a component is new while the newest minor version added it" do
    name, release = ReleaseNotes.new_components.first
    assert_equal release, new_in(name)
    assert_equal release, new_in(name.to_sym)
    assert_nil new_in((ComponentDoc.names - ReleaseNotes.new_components.keys).first)
  end

  test "code is a tinted span, a short word kept on one line and the rest left to wrap" do
    render html: release_text("Re-run `velvetkit:add radio_group` for `vanilla-calendar-pro` in `app/javascript/vanilla_calendar.ts`")
    assert_select "code.bg-muted.font-mono", count: 3
    assert_select "code.whitespace-nowrap", text: "vanilla-calendar-pro"
    assert_select "code.break-words", text: "velvetkit:add radio_group"
    assert_select "code.break-words", text: "app/javascript/vanilla_calendar.ts"
  end
end
