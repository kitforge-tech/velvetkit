# frozen_string_literal: true

module Velvetkit
  # What it takes to use one component: what it is, how to add it, its
  # arguments and slots, its notes and working examples.
  #
  # Read from the registry, so it can't drift from what `add` copies, and
  # written in the app's namespace, so an AI agent reading it writes
  # `Kit::Button` in an app that has Kit::Button. The docs site renders it as
  # HTML; `velvetkit:ai` and llms.txt hand it to agents as Markdown.
  class Reference
    Example = Data.define(:key, :title, :source)

    attr_reader :name, :namespace

    def initialize(name, namespace: Namespace.new(Namespace::CANONICAL), registry: Velvetkit.registry)
      @name = name
      @namespace = namespace
      @registry = registry
    end

    def title = name.humanize
    def description = registry.description(name)
    def add_command = "bin/rails generate velvetkit:add #{name}"

    def class_name
      constant = "#{namespace.name}::#{name.camelize}"
      File.exist?(source_path) ? constant : "#{constant}::*"
    end

    # Other components `add` brings along.
    def dependencies
      registry.resolve([ name ]) - [ "base", name ]
    end

    def stimulus_controllers
      registry.stimulus_controllers(name).map do |file|
        "#{namespace.dom}--#{File.basename(file, "_controller.ts").dasherize}"
      end
    end

    def packages = registry.packages(name) - [ "@hotwired/stimulus" ]
    def gems = registry.gems(name).keys

    # The comment above the class, where a component explains itself.
    def notes
      return unless File.exist?(source_path)

      lines = File.readlines(source_path).drop_while { |line| !line.start_with?("#") || line.include?("frozen_string_literal") }
      comment = lines.take_while { |line| line.start_with?("#") }.map { |line| line.delete_prefix("#").delete_prefix(" ") }
      namespace.rewrite(comment.join).strip.presence
    end

    def signature
      return unless File.exist?(source_path)

      args = File.read(source_path)[/^  def initialize\((.*?)\)\n/m, 1]&.squish
      args && "#{class_name}.new(#{args})"
    end

    def slots
      files = Dir[File.join(registry.root, Registry::COMPONENTS, "#{name}{.rb,/**/*.rb}")]
      files.flat_map do |file|
        source = File.read(file)
        declared = source.scan(/^\s*renders_(one|many) :(\w+)/).map { |kind, slot| "with_#{kind == "many" ? slot.singularize : slot}" }
        declared + source.scan(/^\s*(?:alias_method :|def )(with_\w+)/).flatten
      end.uniq
    end

    # Preview templates, in the order the preview class lists them.
    # Playgrounds take Lookbook params, so they only work inside Lookbook.
    def examples
      labels = preview_labels
      Dir[File.join(previews_root, "#{name}_preview", "[^_]*.html.erb")]
        .map { |file| File.basename(file, ".html.erb") }
        .reject { |key| key == "playground" }
        .sort_by { |key| labels.keys.index(key) || labels.size }
        .map { |key| Example.new(key, labels.fetch(key, key.humanize), namespace.rewrite(File.read(File.join(previews_root, "#{name}_preview", "#{key}.html.erb")))) }
    end

    def to_markdown
      parts = [ "## #{title} (`#{class_name}`)", description ]
      parts << "Add it: `#{add_command}`"
      parts << "Also adds: #{dependencies.map { |d| "`#{d}`" }.join(", ")}" if dependencies.any?
      parts << "Stimulus: #{stimulus_controllers.map { |c| "`#{c}`" }.join(", ")}" if stimulus_controllers.any?
      parts << "Installs: #{(packages + gems).map { |p| "`#{p}`" }.join(", ")}" if (packages + gems).any?
      parts << "### Arguments\n\n```ruby\n#{signature}\n```" if signature
      parts << "Slots: #{slots.map { |s| "`#{s}`" }.join(", ")}" if slots.any?
      parts << "### Notes\n\n#{notes}" if notes
      examples.each { |example| parts << "### Example: #{example.title}\n\n```erb\n#{example.source.strip}\n```" }
      parts.join("\n\n") + "\n"
    end

    private

    attr_reader :registry

    def source_path = File.join(registry.root, Registry::COMPONENTS, "#{name}.rb")
    def previews_root = File.join(registry.root, Registry::PREVIEWS)

    def preview_labels
      preview = File.join(previews_root, "#{name}_preview.rb")
      return {} unless File.exist?(preview)

      File.read(preview).scan(/# @label (.+)\n(?:\s*#.*\n)*\s*def (\w+)/).to_h { |label, method| [ method, label.strip ] }
    end
  end
end
