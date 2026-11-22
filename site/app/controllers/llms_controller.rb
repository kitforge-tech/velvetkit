# The docs in Markdown, for AI agents. llms.txt is the index an agent reads
# first (https://llmstxt.org); llms-full.txt is everything in one file.
class LlmsController < ApplicationController
  def index
    render plain: index_markdown, content_type: "text/plain"
  end

  def full
    guide = Velvetkit.agent_guide(ComponentDoc.names)
    render plain: [ setup, guide, upgrading ].join("\n"), content_type: "text/plain"
  end

  private

  # Upgrading, and what the newest minor version changed, for an agent asked
  # to move an app up a version: the guide page and CHANGELOG.md, one level
  # down so they sit under this file's own headings.
  def upgrading
    html = render_to_string("docs/upgrading", layout: false, formats: [ :html ])
    minor = ReleaseNotes.all.first.minor
    count = ReleaseNotes.all.take_while { _1.minor == minor }.size
    <<~MARKDOWN

      #{demote(PageMarkdown.from_html(html, base_url: request.base_url))}

      ## Release notes for #{minor.join('.')}

      All of them: #{doc_url('releases', format: :md)}

      #{demote(ReleaseNotes.markdown(limit: count))}
    MARKDOWN
  end

  # Every heading one level down, leaving `#` comments in code alone.
  def demote(markdown)
    fenced = false
    markdown.lines.map do |line|
      fenced = !fenced if line.start_with?("```")
      !fenced && line.match?(/\A#+ /) ? "##{line}" : line
    end.join.strip
  end

  def setup
    Rails.root.join("app/views/llms/setup.md").read
  end

  def index_markdown
    components = ComponentDoc.all.map { |c| "- [#{c.title}](#{component_url(c, format: :md)}): #{c.description}" }
    <<~MARKDOWN
      #{setup.split("\n## ").first.strip}

      ## Docs

      - [Full reference](#{llms_full_url}): setup, the rules for building UI with the kit, and every component with examples, in one file
      - [Getting started](#{docs_url(format: :md)}): install the gem and add components
      - [Build with AI](#{doc_url("ai", format: :md)}): how agents get the kit's context in an app
      - [Namespacing](#{doc_url("namespacing", format: :md)}): put the components under a module of your own
      - [Theming](#{doc_url("theming", format: :md)}): colour tokens, corner radius and dark mode
      - [Icons](#{doc_url("icons", format: :md)}): choose an icon library, and add your own
      - [Lookbook](#{doc_url("lookbook", format: :md)}): browse the previews, and run Lookbook in your app
      - [Building forms](#{doc_url("forms", format: :md)}): bind fields to a model and show its errors
      - [Upgrading](#{doc_url("upgrading", format: :md)}): moving an app from one minor version to the next, such as 0.4 to 0.5
      - [Release notes](#{doc_url("releases", format: :md)}): what each version added, changed and fixed, and what to re-run when upgrading

      ## Charts

      - [Overview](#{charts_url(format: :md)}): line, bar, pie and donut charts, their data, formats, colours and accessibility
      - [Line chart](#{chart_doc_url("line", format: :md)}): change over time
      - [Bar chart](#{chart_doc_url("bar", format: :md)}): comparing categories
      - [Stacked bar chart](#{chart_doc_url("stacked_bar", format: :md)}): a total split into its parts
      - [Pie chart](#{chart_doc_url("pie", format: :md)}): one total split into a few parts, at a glance
      - [Donut chart](#{chart_doc_url("donut", format: :md)}): a pie with the total in its middle

      ## Components

      #{components.join("\n")}
    MARKDOWN
  end
end
