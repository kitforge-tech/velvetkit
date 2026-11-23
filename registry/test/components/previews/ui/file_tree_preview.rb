# frozen_string_literal: true

class UI::FileTreePreview < ViewComponent::Preview
  # @label Playground
  # @param guides toggle
  # @param open toggle "Open every folder, whatever the active file"
  # @param links toggle "Files are links, not rows to pick"
  def playground(guides: true, open: false, links: true)
    href = ->(path) { "#/blob/#{path}" if links }
    open = open || nil
    render(UI::FileTree.new(label: "Project files", guides: guides, class: "max-w-xs")) do |tree|
      tree.with_folder(name: "app", open: open) do |app|
        app.with_folder(name: "components", open: open) do |components|
          components.with_file(name: "button.rb", href: href.("app/components/button.rb"), active: true)
          components.with_file(name: "button.html.erb", href: href.("app/components/button.html.erb"))
          components.with_file(name: "card.rb", href: href.("app/components/card.rb"))
        end
        app.with_folder(name: "models", open: open) do |models|
          models.with_file(name: "user.rb", href: href.("app/models/user.rb"))
        end
      end
      tree.with_folder(name: "config", open: open) do |config|
        config.with_file(name: "routes.rb", href: href.("config/routes.rb"))
      end
      tree.with_file(name: "Gemfile", href: href.("Gemfile"))
      tree.with_file(name: "README.md", href: href.("README.md"), icon: "file-text")
    end
  end

  # @label From Data
  def from_data; render_with_template; end

  # @label Picking a File
  def picking_a_file; render_with_template; end

  # @label Changes, with Badges
  def changes; render_with_template; end

  # @label Without Guides
  def without_guides; render_with_template; end
end
