# frozen_string_literal: true

require "minitest/autorun"
require "velvetkit"

# The kit is written with Lucide names and renamed for the app's library on
# the way in (Velvetkit::Icons). That only works if every icon a component
# or preview draws is in registry/icons.yml, and every library has its SVG.
class Velvetkit::IconsTest < Minitest::Test
  def icons = Velvetkit.registry.icons
  def root = Velvetkit.registry.root

  def test_every_icon_the_kit_draws_is_mapped
    missing = drawn.reject { |name, _| icons.canonical.include?(name) }
    assert_empty missing.map { |name, file| "#{name} (#{file})" },
                 "Add these to registry/icons.yml, then run rake icons:sync"
  end

  def test_every_mapped_icon_is_drawn
    assert_empty icons.canonical - drawn.map(&:first), "Nothing draws these: remove them from registry/icons.yml"
  end

  def test_every_library_has_every_svg_and_nothing_else
    Velvetkit::Icons::LIBRARIES.each_key do |library|
      wanted = icons.canonical.map { |icon| icons.svg_file(icon, library) }.uniq.sort
      present = Dir.glob("icons/#{library}/*.svg", base: root).sort
      assert_equal wanted, present, "Run rake icons:sync"
      assert File.exist?(File.join(root, "icons", library, "LICENSE")), "#{library} LICENSE"
    end
  end

  def test_each_svg_keeps_its_license_and_has_a_view_box
    Dir.glob("icons/*/*.svg", base: root).each do |file|
      svg = File.read(File.join(root, file))
      assert_match(/\A<!-- @license \S+ v[\d.]+ - (ISC|MIT) -->\n<svg/, svg, file)
      assert_match(/viewBox="[\d .]+"/, svg, file)
    end
  end

  # Guards the scan: if it stopped finding icons, the tests above would pass
  # for the wrong reason.
  def test_the_scan_finds_icons_drawn_each_way
    names = drawn.map(&:first)
    %w[x search plus check sun info grip-vertical layout-dashboard].each { |icon| assert_includes names, icon }
  end

  def test_names_in_finds_each_form_and_skips_comments
    source = <<~RUBY
      # UI::Icon.new(name: "commented")
      <%# UI::Icon.new(name: "erb-commented") %>
      UI::Icon.new(name: "check")
      with_leading_icon(name: :x)
      dismiss_icon: "info"
      { icon: "sun", text: "Light" }
      DEFAULT_ICONS = { default: "circle-alert", success: "circle-check" }.freeze
      assert_selector "svg[data-icon='moon']"
    RUBY
    assert_equal %w[check x info sun moon circle-alert circle-check].sort, icons.names_in(source).sort
  end

  def test_rewrite_renames_each_form
    source = <<~RUBY
      UI::Icon.new(name: "check")
      with_leading_icon(name: :x)
      with_leading_icon(name: :info)
      dismiss_icon: "circle-alert"
      { icon: "search", text: "Find" }
      DEFAULT_ICONS = { default: "info", success: "circle-check" }.freeze
      assert_selector "svg[data-icon='loader']"
      icon: "not-in-the-map"
      name: "chevron-down"
    RUBY
    assert_equal <<~RUBY, icons.rewrite(source, "phosphor")
      UI::Icon.new(name: "check")
      with_leading_icon(name: :x)
      with_leading_icon(name: :info)
      dismiss_icon: "warning-circle"
      { icon: "magnifying-glass", text: "Find" }
      DEFAULT_ICONS = { default: "info", success: "check-circle" }.freeze
      assert_selector "svg[data-icon='spinner']"
      icon: "not-in-the-map"
      name: "chevron-down"
    RUBY
  end

  def test_rewrite_turns_a_renamed_symbol_into_a_string
    assert_equal %(with_trailing_icon(name: "info-circle")),
                 icons.rewrite("with_trailing_icon(name: :info)", "tabler")
  end

  def test_rewrite_leaves_lucide_alone
    source = %(UI::Icon.new(name: "circle-alert"))
    assert_same source, icons.rewrite(source, "lucide")
  end

  def test_unknown_library
    error = assert_raises(Velvetkit::Error) { Velvetkit::Icons.library!("fontawesome") }
    assert_match "lucide, tabler, phosphor", error.message
  end

  private

  # [icon name, file] for every icon the components and previews draw.
  def drawn
    @drawn ||= Dir.glob("{app/components,test/components/previews}/**/*.{rb,erb}", base: root).flat_map do |file|
      icons.names_in(File.read(File.join(root, file))).map { |name| [ name, file ] }
    end.uniq(&:first)
  end
end
