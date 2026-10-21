# frozen_string_literal: true

require "rails/generators"
require_relative "../helpers"

module Velvetkit
  module Generators
    # Tells AI coding agents how to build UI in this app with its components.
    #
    # Writes docs/velvetkit.md (the rules, then a reference for each installed
    # component, in the app's namespace) and points agents at it: a Claude
    # Code skill, and a section in AGENTS.md for Codex, Cursor and the rest.
    # `add` runs this again whenever the reference exists, so it stays current.
    class AiGenerator < Rails::Generators::Base
      include Helpers

      REFERENCE = "docs/velvetkit.md"
      SKILL = ".claude/skills/velvetkit/SKILL.md"
      MARKER = "<!-- velvetkit -->"

      desc <<~DESC
        Write docs/velvetkit.md for AI agents, describing the components
        installed in this app, and point Claude Code and AGENTS.md at it.
      DESC

      class_option :namespace, type: :string,
                               desc: "Module the components are under (default: #{CONFIG_FILE}, else UI)"

      def write_reference
        create_file REFERENCE, Velvetkit.agent_guide(installed, namespace: kit_namespace), force: true
      end

      def write_claude_skill
        create_file SKILL, <<~MARKDOWN, force: true
          ---
          name: velvetkit
          description: Build Rails UI with this app's #{kit_namespace.name}:: components (VelvetKit ViewComponents). Use when writing or changing views, forms, layouts, pages or ViewComponents.
          ---

          This app's UI is built from VelvetKit components under `#{kit_namespace.name}::`.
          Before writing or changing any view, read `#{REFERENCE}`: it has the rules
          and every installed component's arguments, slots and working examples.

          Need a component that isn't installed? Run `bin/rails generate velvetkit:add <name>`
          instead of writing one.
        MARKDOWN
      end

      def point_agents_md_at_reference
        section = <<~MARKDOWN
          #{MARKER}
          ## UI components

          Build UI from the app's VelvetKit components (`#{kit_namespace.name}::Button`,
          `#{kit_namespace.name}::Dialog`, …). Read `#{REFERENCE}` before writing views: it lists
          the rules and every installed component with working examples.
        MARKDOWN

        agents = File.join(destination_root, "AGENTS.md")
        if !File.exist?(agents)
          create_file "AGENTS.md", "# Agent notes\n\n#{section}"
        elsif !File.read(agents).include?(MARKER)
          append_to_file "AGENTS.md", "\n#{section}"
        end
      end

      private

      # Components present in the app, matched against the registry.
      def installed
        folder = File.join(destination_root, "app/components", kit_namespace.path)
        present = Dir.glob("*.rb", base: folder).map { |file| File.basename(file, ".rb") } +
                  Dir.glob("*/", base: folder).map { |dir| dir.chomp("/") }
        registry.names & present
      end
    end
  end
end
