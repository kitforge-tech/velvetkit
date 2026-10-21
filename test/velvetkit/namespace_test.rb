# frozen_string_literal: true

require "minitest/autorun"
require "velvetkit"

class Velvetkit::NamespaceTest < Minitest::Test
  def kit = Velvetkit::Namespace.new("Kit")

  def test_rejects_names_that_are_not_a_single_constant
    [ "", "kit", "Admin::UI", "My Kit" ].each do |name|
      assert_raises(Velvetkit::Error) { Velvetkit::Namespace.new(name) }
    end
  end

  def test_derives_path_and_dom_prefix
    assert_equal [ "kit", "kit" ], [ kit.path, kit.dom ]

    velvet = Velvetkit::Namespace.new("VelvetKit")
    assert_equal [ "velvet_kit", "velvet-kit" ], [ velvet.path, velvet.dom ]
  end

  def test_all_caps_names_need_an_acronym_inflection
    assert Velvetkit::Namespace.new("UI").acronym?
    assert_equal "ui", Velvetkit::Namespace.new("UI").path
    refute kit.acronym?
  end

  def test_rewrites_paths
    assert_equal "app/components/kit/button.rb", kit.rewrite_path("app/components/ui/button.rb")
    assert_equal "app/javascript/controllers/kit/_internal/use_floating.ts",
                 kit.rewrite_path("app/javascript/controllers/ui/_internal/use_floating.ts")
  end

  def test_rewrites_constants_stimulus_ids_dom_ids_and_i18n_keys
    source = <<~RUBY
      module UI; end
      class UI::Dialog < UI::Base
        def id = "ui-dialog-1"
        def data = { controller: "ui--dialog", "ui--dialog-target": "panel" }
        def label = t("ui.dialog.close_label")
      end
    RUBY

    assert_equal <<~RUBY, kit.rewrite(source)
      module Kit; end
      class Kit::Dialog < Kit::Base
        def id = "kit-dialog-1"
        def data = { controller: "kit--dialog", "kit--dialog-target": "panel" }
        def label = t("kit.dialog.close_label")
      end
    RUBY
  end

  def test_rewrites_keys_and_ids_named_in_markdown_code
    assert_equal "Strings live under `kit.`, ids start `kit-`.", kit.rewrite("Strings live under `ui.`, ids start `ui-`.")
  end

  def test_rewrites_the_locale_scope
    assert_equal "en:\n  kit:\n    button:\n", kit.rewrite("en:\n  ui:\n    button:\n")
  end

  def test_leaves_unrelated_ui_text_alone
    source = "import { computePosition } from '@floating-ui/dom';\n# A UI library for builds\n"
    assert_equal source, kit.rewrite(source)
  end
end
