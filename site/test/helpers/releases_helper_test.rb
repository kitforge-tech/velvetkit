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
    render html: release_component_chip("Carousel")
    assert_select "a", count: 0
    assert_includes rendered, "Carousel"
  end

  test "an upgrade note's lead-in becomes its title" do
    assert_equal [ "Upgrading an app", "Re-run `velvetkit:add card`." ], release_note_parts("Upgrading an app: re-run `velvetkit:add card`.")
    assert_equal [ nil, "Something else." ], release_note_parts("Something else.")
  end

  test "class names in a line link to their component, other code stays code" do
    render html: release_text("`Select` takes `url:`")
    assert_select "a[href='/docs/components/select'] code", text: "Select"
    assert_select "code", text: "url:"
    assert_select "a code", count: 1
  end
end
