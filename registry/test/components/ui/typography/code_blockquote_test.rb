# frozen_string_literal: true

require "test_helper"

class UI::Typography::CodeTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_code_tag
    render_inline(UI::Typography::Code.new) { "npm install" }
    assert_selector "code", text: "npm install"
  end

  def test_has_mono_font_and_background
    render_inline(UI::Typography::Code.new) { "x" }
    classes = page.find("code")[:class].split
    assert_includes classes, "font-mono"
    assert_includes classes, "bg-muted"
    assert_includes classes, "rounded"
  end

  def test_size_variants
    render_inline(UI::Typography::Code.new(size: :sm)) { "small" }
    classes = page.find("code")[:class].split
    assert_includes classes, "text-xs"
  end

  def test_user_class_merge
    render_inline(UI::Typography::Code.new(class: "text-destructive")) { "x" }
    classes = page.find("code")[:class].split
    assert_includes classes, "text-destructive"
  end
end

class UI::Typography::BlockquoteTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_blockquote_tag
    render_inline(UI::Typography::Blockquote.new) { "A famous quote" }
    assert_selector "blockquote", text: "A famous quote"
  end

  def test_has_left_border_and_italic
    render_inline(UI::Typography::Blockquote.new) { "x" }
    classes = page.find("blockquote")[:class].split
    assert_includes classes, "border-l-2"
    assert_includes classes, "italic"
    assert_includes classes, "pl-6"
  end

  def test_user_class_merge
    render_inline(UI::Typography::Blockquote.new(class: "mt-8")) { "x" }
    classes = page.find("blockquote")[:class].split
    assert_includes classes, "mt-8"
  end
end
