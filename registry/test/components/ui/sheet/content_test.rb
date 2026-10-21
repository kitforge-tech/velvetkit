# frozen_string_literal: true

require "test_helper"

class UI::Sheet::ContentTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_sheet(side: :right, **content_opts, &block)
    render_inline(UI::Sheet.new(id: "profile-sheet")) do |sheet|
      sheet.with_trigger { "Open" }
      sheet.with_content(side: side, **content_opts) { |c| block.call(c) }
    end
  end

  # ── Native dialog wrapper ────────────────────────────────────────────────

  def test_renders_native_dialog_element
    render_sheet { |c| c.with_title("Hi") }
    assert_selector "dialog[data-ui--dialog-target='content']", visible: :all
  end

  def test_dialog_has_data_state_closed_by_default
    render_sheet { |c| c.with_title("Hi") }
    assert_equal "closed", page.find("dialog", visible: :all)["data-state"]
    assert_nil page.find("dialog", visible: :all)[:open]
  end

  def test_dialog_id_matches_root
    render_sheet { |c| c.with_title("Hi") }
    assert_equal "profile-sheet", page.find("dialog", visible: :all)[:id]
  end

  def test_panel_present_inside_dialog
    render_sheet { |c| c.with_title("Hi") }
    assert_selector "[data-ui--dialog-part='panel']", visible: :all
  end

  # ── Side variants ────────────────────────────────────────────────────────

  def test_default_side_is_right
    render_sheet { |c| c.with_title("Hi") }
    panel = page.find("[data-ui--dialog-part='panel']", visible: :all)
    assert_includes panel[:class], "right-0"
    assert_includes panel[:class], "h-full"
    assert_includes panel[:class], "max-w-md"
  end

  def test_left_side_positions_sheet_on_left
    render_sheet(side: :left) { |c| c.with_title("Hi") }
    panel = page.find("[data-ui--dialog-part='panel']", visible: :all)
    assert_includes panel[:class], "left-0"
  end

  def test_top_side_positions_sheet_on_top
    render_sheet(side: :top) { |c| c.with_title("Hi") }
    panel = page.find("[data-ui--dialog-part='panel']", visible: :all)
    assert_includes panel[:class], "top-0"
    assert_includes panel[:class], "inset-x-0"
    assert_includes panel[:class], "max-h-[80vh]"
  end

  def test_bottom_side_positions_sheet_on_bottom
    render_sheet(side: :bottom) { |c| c.with_title("Hi") }
    panel = page.find("[data-ui--dialog-part='panel']", visible: :all)
    assert_includes panel[:class], "bottom-0"
  end

  # ── Title / description ──────────────────────────────────────────────────

  def test_title_text_arg_renders_h2
    render_sheet { |c| c.with_title("Are you sure?") }
    title = page.find("dialog h2", visible: :all)
    assert_equal "Are you sure?", title.text.strip
  end

  def test_description_text_arg_renders_p
    render_sheet do |c|
      c.with_title("Hi")
      c.with_description("This action cannot be undone.")
    end
    desc = page.find("dialog p", visible: :all)
    assert_equal "This action cannot be undone.", desc.text.strip
  end

  def test_description_links_via_aria_describedby
    render_sheet do |c|
      c.with_title("Hi")
      c.with_description("Body")
    end
    dialog = page.find("dialog", visible: :all)
    desc   = page.find("dialog p", visible: :all)
    assert_equal "profile-sheet-description", desc[:id]
    assert_equal desc[:id], dialog["aria-describedby"]
  end

  # ── Footer ───────────────────────────────────────────────────────────────

  def test_footer_block_renders_in_footer_element
    render_sheet do |c|
      c.with_title("Hi")
      c.with_footer do
        '<button type="button">Confirm</button>'.html_safe
      end
    end
    assert_selector "dialog footer", visible: :all
    assert_selector "dialog footer button", text: "Confirm", visible: :all
  end

  def test_no_footer_means_no_footer_element
    render_sheet { |c| c.with_title("Hi") }
    assert_no_selector "dialog footer", visible: :all
  end

  # ── Close button ─────────────────────────────────────────────────────────

  def test_close_button_default_present
    render_sheet { |c| c.with_title("Hi") }
    btn = page.find("dialog button[aria-label='Close']", visible: :all)
    assert_match(/click->ui--dialog#close/, btn["data-action"])
  end

  def test_close_button_can_be_disabled
    render_sheet(show_close: false) { |c| c.with_title("Hi") }
    assert_no_selector "dialog button[aria-label='Close']", visible: :all
  end

  # ── User class merge on panel ────────────────────────────────────────────

  def test_user_class_merges_into_panel
    render_sheet(class: "border-red-500") { |c| c.with_title("Hi") }
    panel = page.find("[data-ui--dialog-part='panel']", visible: :all)
    assert_includes panel[:class].split, "border-red-500"
  end
end
