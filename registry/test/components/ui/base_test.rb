# frozen_string_literal: true

require "test_helper"

class UI::BaseTest < ViewComponent::TestCase
  # Component tests do not need DB fixtures. Test_helper applies `fixtures :all`
  # globally; admin_users fixtures are pre-existing-broken (duplicate empty emails).
  # Skip fixture setup for this test class.
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  class Probe < UI::Base
    def call
      tag.div(class: cn(*@parts)) { "x" }
    end

    def initialize(*parts)
      @parts = parts
    end
  end

  def test_cn_concatenates_string_classes
    render_inline Probe.new("p-2", "rounded-md")
    assert_selector "div.p-2.rounded-md"
  end

  def test_cn_drops_nil_and_blank_inputs
    render_inline Probe.new("p-2", nil, "", "rounded-md")
    assert_selector "div.p-2.rounded-md"
  end

  def test_cn_supports_conditional_hash
    render_inline Probe.new("base", { "active-class" => true, "hidden-class" => false })
    div = page.find("div")
    assert_includes div[:class], "base"
    assert_includes div[:class], "active-class"
    refute_includes div[:class], "hidden-class"
  end

  def test_cn_resolves_tailwind_conflicts_user_wins
    render_inline Probe.new("bg-primary text-primary-foreground", "bg-red-500")
    div = page.find("div")
    refute_includes div[:class], "bg-primary"
    assert_includes div[:class], "bg-red-500"
    assert_includes div[:class], "text-primary-foreground"
  end

  class VariantProbe < UI::Base
    variants(
      base: "btn",
      variants: {
        variant: { default: "bg-primary", outline: "border" },
        size:    { sm: "h-8", lg: "h-10" }
      },
      defaults: { variant: :default, size: :sm },
      compound: [
        { when: { variant: :outline, size: :lg }, class: "border-2" }
      ]
    )

    def initialize(variant: nil, size: nil)
      @variant = variant
      @size = size
    end

    def call
      tag.button(class: variant_classes(variant: @variant, size: @size)) { "x" }
    end
  end

  def test_variants_uses_defaults_when_no_props_passed
    render_inline VariantProbe.new
    btn = page.find("button")
    assert_includes btn[:class], "btn"
    assert_includes btn[:class], "bg-primary"
    assert_includes btn[:class], "h-8"
  end

  def test_variants_overrides_defaults_with_passed_props
    render_inline VariantProbe.new(variant: :outline, size: :lg)
    btn = page.find("button")
    assert_includes btn[:class], "border"
    assert_includes btn[:class], "h-10"
    refute_includes btn[:class], "bg-primary"
  end

  def test_variants_applies_compound_rule_when_all_conditions_match
    render_inline VariantProbe.new(variant: :outline, size: :lg)
    btn = page.find("button")
    assert_includes btn[:class], "border-2"
  end

  def test_variants_skips_compound_rule_when_any_condition_misses
    render_inline VariantProbe.new(variant: :outline, size: :sm)
    btn = page.find("button")
    refute_includes btn[:class], "border-2"
  end

  # The ring on click is VelvetKit's signature (AGENTS.md, "Focus rings"):
  # 0.5.0 moved it to :focus-visible by mistake and 0.5.1 put it back. If this
  # fails, don't rewrite it to match; ask the maintainer first.
  def test_the_focus_ring_shows_on_click
    assert_includes UI::Base::FOCUS_RING, "focus:ring-2"
    assert_includes UI::Base::FOCUS_RING, "focus:ring-primary"
    refute_match(/focus-visible:ring/, UI::Base::FOCUS_RING)
  end

  # Components whose ring is keyboard-only, each a deliberate choice made
  # before 0.5. A new one needs the maintainer's sign-off, then a place here.
  KEYBOARD_ONLY_RINGS = %w[
    input_group/addon navigation_menu/item navigation_menu/link scrubber
    session_tabs/tab slider stepper/step
  ].freeze

  def test_no_other_component_has_a_keyboard_only_ring
    # Beside base.rb, wherever the kit is (the namespaced run renames ui/).
    root = File.dirname(Object.const_source_location(UI::Base.name).first)
    keyboard_only = Dir.glob("**/*.{rb,html.erb}", base: root).select do |file|
      File.read(File.join(root, file)).match?(/focus-visible:ring/)
    end.map { _1.sub(/\.(rb|html\.erb)\z/, "") }.uniq.sort

    assert_equal KEYBOARD_ONLY_RINGS.sort, keyboard_only,
                 "The focus ring shows on click as well as on Tab (AGENTS.md). Ask the maintainer before using :focus-visible."
  end
end
