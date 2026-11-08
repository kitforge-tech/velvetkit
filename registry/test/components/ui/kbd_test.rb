# frozen_string_literal: true

require "test_helper"

class UI::KbdTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  MAC = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/130.0 Safari/537.36"
  WINDOWS = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/130.0 Safari/537.36"

  def render_kbd(*args, agent: WINDOWS, **opts, &block)
    vc_test_request.user_agent = agent
    render_inline(UI::Kbd.new(*args, **opts), &block)
  end

  def test_a_letter_on_its_own_is_lowercase_since_that_is_what_you_type
    render_kbd("K")
    assert_selector "kbd[data-slot='kbd'][data-controller='ui--kbd'] > span > kbd", exact_text: "k"
  end

  def test_a_letter_with_a_modifier_is_a_capital_and_shift_is_written_out
    render_kbd("mod+k")
    assert_selector "kbd", exact_text: "K"
    render_kbd("shift+g")
    assert_selector "span.sr-only", text: "Shift", visible: :all
    assert_selector "kbd", exact_text: "G"
    render_kbd("alt+n")
    assert_selector "kbd", exact_text: "N"
  end

  def test_guesses_the_platform_from_the_user_agent
    render_kbd("mod+k", agent: MAC)
    assert_selector "[data-slot='kbd'][data-platform='mac']"
    render_kbd("mod+k", agent: WINDOWS)
    assert_selector "[data-slot='kbd'][data-platform='other']"
  end

  def test_mod_is_command_on_a_mac_and_ctrl_elsewhere_shown_by_platform
    render_kbd("mod+k")
    mac = page.find("kbd.hidden", visible: :all)
    assert_includes mac[:class], "group-data-[platform=mac]/kbd:inline-flex"
    assert_equal "⌘", mac.find("span[aria-hidden]", visible: :all).text(:all)
    assert_equal "Command", mac.find("span.sr-only", visible: :all).text(:all)
    other = page.find("kbd.group-data-\\[platform\\=mac\\]\\/kbd\\:hidden")
    assert_equal "Ctrl", other.find("span[aria-hidden]").text
    assert_equal "Control", other.find("span.sr-only", visible: :all).text(:all)
  end

  def test_a_plus_between_keys_only_off_a_mac
    render_kbd("ctrl+shift+p")
    assert_selector "span[aria-hidden='true'].group-data-\\[platform\\=mac\\]\\/kbd\\:hidden", text: "+", count: 2
  end

  def test_symbols_carry_their_names_for_screen_readers
    render_kbd("shift+enter")
    assert_selector "span.sr-only", text: "Shift", visible: :all
    assert_selector "span.sr-only", text: "Return", visible: :all
    assert_selector "kbd", text: "Enter"
  end

  def test_aliases_and_keys_that_read_the_same_everywhere
    render_kbd("escape")
    assert_equal [ "Esc" ], page.all("[data-slot='kbd'] kbd span[aria-hidden]").map(&:text)
    assert_selector "span.sr-only", text: "Escape", visible: :all, count: 1
    render_kbd("space")
    assert_selector "[data-slot='kbd'] kbd", text: "Space"
    assert_no_selector "span.sr-only", visible: :all
    render_kbd("option+up")
    assert_selector "span.sr-only", text: "Option", visible: :all
    assert_selector "kbd", text: "Alt"
    assert_selector "span.sr-only", text: "Up Arrow", visible: :all, count: 1
  end

  def test_other_keys_are_shown_as_written
    render_kbd("F5")
    assert_selector "kbd > span > kbd", text: "F5"
    render_kbd("/")
    assert_selector "kbd > span > kbd", text: "/"
  end

  def test_a_sequence_says_then_between_its_steps
    render_kbd(%w[g i])
    assert_selector "[data-slot='kbd'] > span", text: "then"
    assert_equal %w[g i], page.all("[data-slot='kbd'] kbd").map(&:text)
  end

  def test_a_written_key_is_shown_as_given
    render_kbd { "Fn" }
    assert_selector "[data-slot='kbd'] > kbd", text: "Fn"
  end

  def test_sizes
    render_kbd("k", size: :lg)
    assert_selector "kbd kbd.h-6.text-sm"
    render_kbd("k", size: :nonsense)
    assert_selector "kbd kbd.h-5.text-xs"
  end

  def test_takes_its_colour_from_the_text_around_it
    render_kbd("k")
    assert_selector "[data-slot='kbd'].text-current\\/80"
    assert_selector "kbd kbd.border-current\\/15"
  end

  def test_binding_hands_the_shortcut_to_the_controller
    render_kbd("mod+s", bind: true)
    assert_selector "[data-ui--kbd-keys-value='mod+s'][data-ui--kbd-target-value='']"
    render_kbd("mod+s", bind: "#save")
    assert_selector "[data-ui--kbd-keys-value='mod+s'][data-ui--kbd-target-value='#save']"
  end

  def test_a_sequence_or_an_unbound_hint_is_not_bound
    render_kbd(%w[g i], bind: true)
    assert_no_selector "[data-ui--kbd-keys-value]"
    render_kbd("mod+s")
    assert_no_selector "[data-ui--kbd-keys-value]"
  end

  def test_passes_class_and_attributes_through
    render_kbd("k", class: "ms-auto", id: "hint", data: { testid: "kbd" })
    assert_selector "kbd#hint.ms-auto[data-testid='kbd'][data-controller='ui--kbd']"
  end
end
