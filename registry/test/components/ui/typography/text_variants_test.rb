# frozen_string_literal: true

require "test_helper"

class UI::Typography::LeadTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_p_tag
    render_inline(UI::Typography::Lead.new) { "Lead paragraph" }
    assert_selector "p", text: "Lead paragraph"
  end

  def test_has_muted_foreground
    render_inline(UI::Typography::Lead.new) { "x" }
    classes = page.find("p")[:class].split
    assert_includes classes, "text-xl"
    assert_includes classes, "text-muted-foreground"
  end
end

class UI::Typography::MutedTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_p_tag
    render_inline(UI::Typography::Muted.new) { "Muted text" }
    assert_selector "p", text: "Muted text"
  end

  def test_has_small_muted_text
    render_inline(UI::Typography::Muted.new) { "x" }
    classes = page.find("p")[:class].split
    assert_includes classes, "text-sm"
    assert_includes classes, "text-muted-foreground"
  end
end

class UI::Typography::SmallTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_small_tag
    render_inline(UI::Typography::Small.new) { "Small text" }
    assert_selector "small", text: "Small text"
  end

  def test_has_extra_small_text
    render_inline(UI::Typography::Small.new) { "x" }
    classes = page.find("small")[:class].split
    assert_includes classes, "text-xs"
    assert_includes classes, "font-medium"
  end
end

class UI::Typography::LargeTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_div_tag
    render_inline(UI::Typography::Large.new) { "Large text" }
    assert_selector "div", text: "Large text"
  end

  def test_has_large_semibold_text
    render_inline(UI::Typography::Large.new) { "x" }
    classes = page.find("div")[:class].split
    assert_includes classes, "text-lg"
    assert_includes classes, "font-semibold"
  end
end
