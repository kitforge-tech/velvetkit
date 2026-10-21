# What the header search looks through: every guide and every component,
# with words people might type that don't appear in the title.
class SearchIndex
  Entry = Data.define(:group, :title, :description, :url, :keywords)

  GUIDES = {
    "getting_started" => [ "Install the gem, set it up and add your first component.", "install gemfile bundle generator setup add render requirements" ],
    "ai" => [ "Give coding agents the kit's context: llms.txt, docs/velvetkit.md and a Claude Code skill.", "ai agent claude cursor codex copilot llms prompt skill agents.md markdown" ],
    "namespacing" => [ "Put the components under any module, like Kit:: or Admin::.", "namespace module ui kit rename acronym inflection zeitwerk" ],
    "theming" => [ "Colour tokens, corner radius and dark mode: retheme every component from one file.", "theme tokens colour color primary radius dark mode css tailwind velvet" ],
    "lookbook" => [ "Browse every preview, and run Lookbook in your app.", "lookbook preview previews playground storybook" ]
  }.freeze

  def self.entries
    new.entries
  end

  def entries
    all = Entry.new(group: "Components", title: "All components", url: routes.components_path,
                    description: "Every component, with search.", keywords: "list browse overview")
    guides + [ all ] + components
  end

  private

  def guides
    DocsController::PAGES.map do |page, title|
      summary, keywords = GUIDES.fetch(page)
      url = page == "getting_started" ? routes.docs_path : routes.doc_path(page)
      Entry.new(group: "Guides", title: title, url: url, description: summary, keywords: keywords)
    end
  end

  def components
    ComponentDoc.all.map do |component|
      keywords = [ component.name.tr("_", " "), component.class_name, *component.slots, *component.stimulus_controllers ].join(" ")
      Entry.new(group: "Components", title: component.title, url: routes.component_path(component),
                description: component.description, keywords: keywords)
    end
  end

  def routes = Rails.application.routes.url_helpers
end
