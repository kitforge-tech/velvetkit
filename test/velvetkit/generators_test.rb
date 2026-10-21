# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "generators/velvetkit/install/install_generator"
require "generators/velvetkit/add/add_generator"

class Velvetkit::GeneratorsTest < Minitest::Test
  def setup
    @app = Dir.mktmpdir("velvetkit-app")
    write "Gemfile", %(source "https://rubygems.org"\ngem "rails"\n)
    write "app/assets/tailwind/application.css", %(@import "tailwindcss";\n\nbody {}\n)
    write "app/javascript/application.js", %(import "./controllers"\n)
    write "app/javascript/controllers/index.js",
          %(import { application } from "./application"\n\nimport HelloController from "./hello_controller"\napplication.register("hello", HelloController)\n)
  end

  def teardown
    FileUtils.rm_rf(@app)
  end

  def test_install_sets_up_the_namespace_and_foundation
    install "--namespace=Kit"

    assert_match "namespace: Kit", read("config/velvetkit.yml")
    assert_match "class Kit::Base", read("app/components/kit/base.rb")
    assert_match "  kit:", read("config/locales/velvetkit.en.yml")
    assert exist?("app/assets/tailwind/velvetkit.css")
    assert_match %(@import "tailwindcss";\n@import "./velvetkit.css";), read("app/assets/tailwind/application.css")
    assert_match %(import "./velvetkit_icons"), read("app/javascript/application.js")
    assert_match %(gem "view_component"), read("Gemfile")
    assert_match %(gem "tailwind_merge"), read("Gemfile")
    refute exist?("config/initializers/inflections.rb"), "Kit needs no inflection"
  end

  def test_install_adds_an_acronym_inflection_when_the_namespace_needs_one
    install "--namespace=UI"

    assert_match %(inflect.acronym "UI"), read("config/initializers/inflections.rb")
    assert exist?("app/components/ui/base.rb")
  end

  def test_add_copies_only_the_component_and_what_it_uses
    install "--namespace=Kit"
    add "popover"

    %w[base button icon spinner popover].each do |name|
      assert exist?("app/components/kit/#{name}.rb"), name
      assert exist?("test/components/kit/#{name}_test.rb"), name
    end
    refute exist?("app/components/kit/dialog.rb")
    assert exist?("app/javascript/controllers/kit/popover_controller.ts")
    assert exist?("app/javascript/controllers/kit/_internal/use_floating.ts")
    refute exist?("app/javascript/controllers/kit/dialog_controller.ts")
  end

  def test_add_reads_the_namespace_from_config
    install "--namespace=Kit"
    add "badge"

    assert_match "class Kit::Badge < Kit::Base", read("app/components/kit/badge.rb")
  end

  def test_add_registers_stimulus_controllers_once
    install "--namespace=Kit"
    add "sheet"
    add "dialog"

    manifest = read("app/javascript/controllers/index.js")
    assert_match %(import Kit__DialogController from "./kit/dialog_controller"), manifest
    assert_equal 1, manifest.scan('register("kit--dialog"').size
    assert_match 'application.register("hello"', manifest
  end

  def test_add_skips_a_preview_that_shows_components_not_installed
    install "--namespace=Kit"
    add "theme_toggle"

    refute exist?("test/components/previews/kit/theme_toggle_preview.rb")
    assert exist?("test/components/previews/kit/menu_preview.rb")
  end

  def test_add_can_leave_out_tests_and_previews
    install "--namespace=Kit"
    add "badge", "--skip-tests", "--skip-previews"

    assert exist?("app/components/kit/badge.rb")
    refute exist?("test/components/kit/badge_test.rb")
    refute exist?("test/components/previews/kit/badge_preview.rb")
  end

  def test_add_puts_the_gems_a_component_needs_in_the_gemfile
    install "--namespace=Kit"
    add "pagination"

    assert_match %(gem "pagy", "~> 43.0"), read("Gemfile")
  end

  def test_add_with_no_components_only_lists_them
    install "--namespace=Kit"
    output = add.first

    assert_match "dialog", output
    refute exist?("app/components/kit/dialog.rb")
  end

  def test_add_all_copies_every_component
    install "--namespace=Kit"
    add "--all", "--skip-tests", "--skip-previews"

    assert exist?("app/components/kit/data_grid.rb")
    assert exist?("app/javascript/cally.ts")
  end

  def test_install_imports_tokens_into_a_cssbundling_entry_point
    FileUtils.rm(File.join(@app, "app/assets/tailwind/application.css"))
    write "app/assets/stylesheets/application.tailwind.css", %(@import "tailwindcss";\n)
    install "--namespace=Kit"

    assert_match %(@import "../tailwind/velvetkit.css";), read("app/assets/stylesheets/application.tailwind.css")
  end

  def test_add_registers_controllers_in_a_manifest_that_lists_none_yet
    write "app/javascript/controllers/index.js", %(import { application } from "./application"\n)
    install "--namespace=Kit"
    add "tabs"

    assert_match 'application.register("kit--tabs"', read("app/javascript/controllers/index.js")
  end

  def test_add_leaves_a_directory_loading_manifest_alone
    manifest = %(import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"\neagerLoadControllersFrom("controllers", application)\n)
    write "app/javascript/controllers/index.js", manifest
    install "--namespace=Kit"
    add "tabs"

    assert_equal manifest, read("app/javascript/controllers/index.js")
  end

  def test_install_writes_an_agent_reference_in_the_apps_namespace
    install "--namespace=Kit"

    reference = read("docs/velvetkit.md")
    assert_match "app/components/kit/", reference
    assert_match "Available: accordion", reference
    refute_match(/\bUI::|ui--/, reference)
    assert_match "docs/velvetkit.md", read(".claude/skills/velvetkit/SKILL.md")
    assert_match "Kit::Button", read("AGENTS.md")
  end

  def test_add_refreshes_the_agent_reference_with_new_components
    install "--namespace=Kit"
    refute_match "## Dialog", read("docs/velvetkit.md")

    add "dialog"

    reference = read("docs/velvetkit.md")
    assert_match "## Dialog (`Kit::Dialog`)", reference
    assert_match "## Button (`Kit::Button`)", reference
    assert_match "```erb", reference
  end

  def test_ai_appends_to_an_existing_agents_md_once
    write "AGENTS.md", "# Our rules\n\nUse tabs.\n"
    install "--namespace=Kit"
    add "badge"

    agents = read("AGENTS.md")
    assert agents.start_with?("# Our rules")
    assert_equal 1, agents.scan("<!-- velvetkit -->").size
  end

  def test_install_can_skip_the_agent_reference
    install "--namespace=Kit", "--skip-ai"

    refute exist?("docs/velvetkit.md")
    refute exist?("AGENTS.md")
  end

  private

  def install(*args)
    run_generator Velvetkit::Generators::InstallGenerator, args
  end

  def add(*args)
    run_generator Velvetkit::Generators::AddGenerator, args
  end

  def run_generator(generator, args)
    capture_io { generator.start(args + %w[--skip-packages], destination_root: @app) }
  end

  def write(file, content)
    FileUtils.mkdir_p(File.dirname(File.join(@app, file)))
    File.write(File.join(@app, file), content)
  end

  def read(file) = File.read(File.join(@app, file))
  def exist?(file) = File.exist?(File.join(@app, file))
end
