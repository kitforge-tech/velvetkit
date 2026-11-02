# frozen_string_literal: true

require "minitest/autorun"
require "velvetkit"

# velvetkit_icons.ts bundles a fixed list of Lucide icons into every app. An
# icon a component draws that isn't on the list renders as an empty element,
# with no error. The docs site can't catch that: it also loads every Lucide
# icon for its examples (site/app/javascript/site_icons.js). So check the
# list against the components' source.
class Velvetkit::IconsTest < Minitest::Test
  ICONS_FILE = "app/javascript/velvetkit_icons.ts"

  def registry = Velvetkit.registry

  def test_every_icon_a_component_draws_is_bundled
    missing = drawn_icons.reject { |name, _| bundled.include?(name) }
    assert_empty missing.map { |name, file| "#{name} (#{file})" },
                 "Add these to both lists in registry/#{ICONS_FILE}"
  end

  def test_the_import_list_and_the_icons_object_match
    imported = icons_source[/import \{(.*?)\} from 'lucide'/m, 1].scan(/\b[A-Z]\w*/)
    registered = icons_source[/const icons = \{(.*?)\};/m, 1].scan(/\b[A-Z]\w*/)
    assert_equal imported.sort, registered.sort
  end

  # Guards the scan below: if it stopped finding anything, the first test
  # would pass for the wrong reason.
  def test_the_scan_finds_icons_drawn_each_way
    names = drawn_icons.map(&:first)
    %w[x search plus check sun info grip-vertical].each { |icon| assert_includes names, icon }
  end

  private

  def icons_source = @icons_source ||= File.read(File.join(registry.root, ICONS_FILE))

  # Lucide's export names, as the kebab-case names components use:
  # ChevronsUpDown -> chevrons-up-down, X -> x.
  def bundled
    @bundled ||= icons_source[/const icons = \{(.*?)\};/m, 1].scan(/\b[A-Z]\w*/).map do |export|
      export.gsub(/(?<=[a-z0-9])(?=[A-Z])/, "-").downcase
    end
  end

  # [icon name, file] for every icon the components' own code draws, written
  # any of the ways it is in the kit:
  #   UI::Icon.new(name: "check")   with_leading_icon(name: :x)
  #   dismiss_icon: "x"             { icon: "sun" }
  #   DEFAULT_ICONS = { default: "info", … }
  # Comments are skipped. Icons an app passes in (a link's `icon:`) aren't
  # the kit's to bundle.
  def drawn_icons
    @drawn_icons ||= Dir.glob("app/components/**/*.{rb,erb}", base: registry.root).flat_map do |file|
      code = File.read(File.join(registry.root, file)).gsub(/<%#.*?%>/m, "").lines.grep_v(/\A\s*#/).join
      names = code.scan(/(?:Icon\.new|_icon)\(\s*name:\s*[:"]([a-z0-9-]+)/).flatten
      names += code.scan(/\b(?:\w+_)?icon:\s*"([a-z0-9-]+)"/).flatten
      code.scan(/ICONS\s*=\s*\{(.*?)\}/m).flatten.each { |map| names += map.scan(/"([a-z0-9-]+)"/).flatten }
      names.uniq.map { |name| [ name, file ] }
    end.uniq(&:first)
  end
end
