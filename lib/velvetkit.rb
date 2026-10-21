# frozen_string_literal: true

require "velvetkit/version"
require "velvetkit/namespace"
require "velvetkit/registry"
require "velvetkit/reference"

# VelvetKit copies ViewComponent UI components into a Rails app, one at a time
# and under the namespace the app chooses. Nothing runs from the gem at
# runtime: once copied, the components are the app's own code.
module Velvetkit
  class Error < StandardError; end

  CONFIG_FILE = "config/velvetkit.yml"

  def self.registry
    @registry ||= Registry.new(File.expand_path("../registry", __dir__))
  end

  # Everything an AI agent needs to build UI in an app: the rules, then a
  # reference for each component, all in the app's namespace.
  def self.agent_guide(components, namespace: Namespace.new(Namespace::CANONICAL))
    guide = File.read(File.join(registry.root, "docs/agents.md"))
                .sub("{{available}}", (registry.names - [ "base" ]).join(", "))
    references = (components - [ "base" ]).map { |name| Reference.new(name, namespace: namespace).to_markdown }
    ([ namespace.rewrite(guide) ] + references).join("\n")
  end
end
