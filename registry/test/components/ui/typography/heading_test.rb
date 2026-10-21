# frozen_string_literal: true

require "test_helper"

class UI::Typography::H1Test < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_h1_tag
    render_inline(UI::Typography::H1.new) { "Heading 1" }
    assert_selector "h1", text: "Heading 1"
  end

  def test_has_correct_classes
    render_inline(UI::Typography::H1.new) { "x" }
    classes = page.find("h1")[:class].split
    assert_includes classes, "text-4xl"
    assert_includes classes, "font-bold"
  end
end

class UI::Typography::H2Test < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_h2_tag
    render_inline(UI::Typography::H2.new) { "Heading 2" }
    assert_selector "h2", text: "Heading 2"
  end

  def test_has_correct_classes
    render_inline(UI::Typography::H2.new) { "x" }
    classes = page.find("h2")[:class].split
    assert_includes classes, "text-3xl"
    assert_includes classes, "font-semibold"
  end
end

class UI::Typography::H3Test < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_h3_tag
    render_inline(UI::Typography::H3.new) { "Heading 3" }
    assert_selector "h3", text: "Heading 3"
  end

  def test_has_correct_classes
    render_inline(UI::Typography::H3.new) { "x" }
    classes = page.find("h3")[:class].split
    assert_includes classes, "text-2xl"
    assert_includes classes, "font-semibold"
  end
end

class UI::Typography::H4Test < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_h4_tag
    render_inline(UI::Typography::H4.new) { "Heading 4" }
    assert_selector "h4", text: "Heading 4"
  end

  def test_has_correct_classes
    render_inline(UI::Typography::H4.new) { "x" }
    classes = page.find("h4")[:class].split
    assert_includes classes, "text-xl"
    assert_includes classes, "font-semibold"
  end
end
