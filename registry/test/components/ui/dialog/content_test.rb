# frozen_string_literal: true

require "test_helper"

class UI::Dialog::ContentTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_dialog(content_opts = {}, &block)
    render_inline(UI::Dialog.new(id: "profile-dialog")) do |dlg|
      dlg.with_trigger { "Open" }
      dlg.with_content(**content_opts) { |c| block.call(c) }
    end
  end

  # ── Native dialog wrapper ────────────────────────────────────────────────

  def test_renders_native_dialog_element
    render_dialog { |c| c.with_title("Hi") }
    assert_selector "dialog[data-ui--dialog-target='content']", visible: :all
  end

  def test_dialog_has_data_state_closed_by_default
    render_dialog { |c| c.with_title("Hi") }
    assert_equal "closed", page.find("dialog", visible: :all)["data-state"]
    assert_nil page.find("dialog", visible: :all)[:open]
  end

  def test_dialog_id_matches_root
    render_dialog { |c| c.with_title("Hi") }
    assert_equal "profile-dialog", page.find("dialog", visible: :all)[:id]
  end

  def test_panel_present_inside_dialog
    render_dialog { |c| c.with_title("Hi") }
    assert_selector "[data-ui--dialog-part='panel']", visible: :all
  end

  # ── Title / description ──────────────────────────────────────────────────

  def test_title_text_arg_renders_h2
    render_dialog { |c| c.with_title("Are you sure?") }
    title = page.find("dialog h2", visible: :all)
    assert_equal "Are you sure?", title.text.strip
    classes = title[:class].split
    assert_includes classes, "text-lg"
    assert_includes classes, "font-semibold"
  end

  def test_title_block_renders_h2_with_block_content
    render_dialog do |c|
      c.with_title { "Block title" }
    end
    title = page.find("dialog h2", visible: :all)
    assert_equal "Block title", title.text.strip
  end

  def test_title_links_via_aria_labelledby
    render_dialog { |c| c.with_title("Hi") }
    dialog = page.find("dialog", visible: :all)
    title  = page.find("dialog h2", visible: :all)
    assert_equal "profile-dialog-title", title[:id]
    assert_equal title[:id], dialog["aria-labelledby"]
  end

  def test_description_text_arg_renders_p
    render_dialog do |c|
      c.with_title("Hi")
      c.with_description("This action cannot be undone.")
    end
    desc = page.find("dialog p", visible: :all)
    assert_equal "This action cannot be undone.", desc.text.strip
    assert_includes desc[:class].split, "text-muted-foreground"
  end

  def test_description_links_via_aria_describedby
    render_dialog do |c|
      c.with_title("Hi")
      c.with_description("Body")
    end
    dialog = page.find("dialog", visible: :all)
    desc   = page.find("dialog p", visible: :all)
    assert_equal "profile-dialog-description", desc[:id]
    assert_equal desc[:id], dialog["aria-describedby"]
  end

  def test_no_title_means_no_aria_labelledby
    render_dialog { |c| c.with_description("Body") }
    refute page.find("dialog", visible: :all)["aria-labelledby"]
  end

  # ── Body ─────────────────────────────────────────────────────────────────

  def test_body_content_renders_inside_dialog
    render_dialog do |c|
      c.with_title("Hi")
      "raw body text"
    end
    assert_selector "dialog", text: "raw body text", visible: :all
  end

  # ── Footer ───────────────────────────────────────────────────────────────

  def test_footer_block_renders_in_footer_element
    render_dialog do |c|
      c.with_title("Hi")
      c.with_footer do
        '<button type="button">Confirm</button>'.html_safe
      end
    end
    assert_selector "dialog footer", visible: :all
    assert_selector "dialog footer button", text: "Confirm", visible: :all
  end

  def test_no_footer_means_no_footer_element
    render_dialog { |c| c.with_title("Hi") }
    assert_no_selector "dialog footer", visible: :all
  end

  # ── Close button ─────────────────────────────────────────────────────────

  def test_close_button_default_present
    render_dialog { |c| c.with_title("Hi") }
    btn = page.find("dialog button[aria-label='Close']", visible: :all)
    assert_match(/click->ui--dialog#close/, btn["data-action"])
  end

  def test_close_button_can_be_disabled
    render_dialog(show_close: false) { |c| c.with_title("Hi") }
    assert_no_selector "dialog button[aria-label='Close']", visible: :all
  end

  # ── Sizes ────────────────────────────────────────────────────────────────

  def test_size_default
    render_dialog { |c| c.with_title("Hi") }
    panel = page.find("[data-ui--dialog-part='panel']", visible: :all)
    assert_includes panel[:class].split, "max-w-lg"
  end

  def test_other_sizes_apply_max_width_token
    { sm: "max-w-md", lg: "max-w-2xl", xl: "max-w-4xl" }.each do |size, expected|
      render_dialog(size: size) { |c| c.with_title("Hi") }
      panel = page.find("[data-ui--dialog-part='panel']", visible: :all)
      assert_includes panel[:class].split, expected, "size #{size}"
    end
  end

  # ── User class merge on panel ────────────────────────────────────────────

  def test_user_class_merges_into_panel
    render_dialog(class: "border-red-500") { |c| c.with_title("Hi") }
    panel = page.find("[data-ui--dialog-part='panel']", visible: :all)
    assert_includes panel[:class].split, "border-red-500"
  end
end
