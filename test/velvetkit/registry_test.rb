# frozen_string_literal: true

require "minitest/autorun"
require "velvetkit"
require "tmpdir"
require "fileutils"

class Velvetkit::RegistryTest < Minitest::Test
  def registry = Velvetkit.registry

  def test_every_component_directory_is_in_the_catalog
    on_disk = Dir.glob("*.rb", base: File.join(registry.root, Velvetkit::Registry::COMPONENTS)).map { |f| File.basename(f, ".rb") }
    on_disk += Dir.glob("*/", base: File.join(registry.root, Velvetkit::Registry::COMPONENTS)).map { |d| d.chomp("/") }

    assert_empty on_disk.uniq - registry.names
  end

  def test_every_component_has_files_and_a_description
    registry.names.each do |name|
      refute_empty registry.component_files(name), name
      refute_empty registry.description(name), name
    end
  end

  def test_every_controller_belongs_to_some_component
    shipped = registry.names.flat_map { |name| registry.javascript_files(name) }
    on_disk = Dir.glob("#{Velvetkit::Registry::CONTROLLERS}/**/*.ts", base: registry.root)

    assert_empty on_disk - shipped, "controllers no component uses"
  end

  def test_every_imported_package_has_a_version
    (registry.names.flat_map { |name| registry.packages(name) } + Velvetkit::Registry::FOUNDATION_PACKAGES).uniq.each do |package|
      assert registry.package_version(package), package
    end
  end

  def test_resolve_adds_dependencies_before_dependents
    resolved = registry.resolve(%w[password_input])

    assert_equal "base", resolved.first
    assert_equal "password_input", resolved.last
    assert_includes resolved, "input_group"
    assert_operator resolved.index("label"), :<, resolved.index("input")
    refute_includes resolved, "dialog"
  end

  def test_resolve_rejects_unknown_components
    error = assert_raises(Velvetkit::Error) { registry.resolve(%w[carousel]) }
    assert_match "carousel", error.message
  end

  def test_a_component_named_only_in_a_comment_is_not_a_dependency
    refute_includes registry.dependencies("select"), "native_select"
    refute_includes registry.dependencies("native_select"), "select"
  end

  def test_resolve_survives_components_that_render_each_other
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "app/components/ui"))
      File.write(File.join(root, "components.yml"), { "components" => { "base" => {}, "a" => {}, "b" => {} } }.to_yaml)
      File.write(File.join(root, "app/components/ui/base.rb"), "")
      File.write(File.join(root, "app/components/ui/a.rb"), "UI::B.new")
      File.write(File.join(root, "app/components/ui/b.rb"), "UI::A.new")

      assert_equal %w[base a b].sort, Velvetkit::Registry.new(root).resolve(%w[a]).sort
    end
  end

  def test_finds_controllers_helpers_and_entry_points
    assert_equal %w[
      app/javascript/controllers/ui/popover_controller.ts
      app/javascript/controllers/ui/_internal/use_floating.ts
      app/javascript/controllers/ui/_internal/use_dismiss.ts
    ].sort, registry.javascript_files("popover").sort

    assert_includes registry.javascript_files("date_picker"), "app/javascript/cally.ts"
    assert_equal %w[app/javascript/controllers/ui/dialog_controller.ts], registry.stimulus_controllers("sheet")
  end

  def test_reads_packages_from_imports
    assert_equal %w[@floating-ui/dom @hotwired/stimulus], registry.packages("tooltip")
    assert_equal %w[@hotwired/stimulus ag-grid-community], registry.packages("data_grid")
    assert_empty registry.packages("badge")
  end
end
