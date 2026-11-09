# The docs in Markdown, for AI agents. llms.txt is the index an agent reads
# first (https://llmstxt.org); llms-full.txt is everything in one file.
class LlmsController < ApplicationController
  def index
    render plain: index_markdown, content_type: "text/plain"
  end

  def full
    guide = Velvetkit.agent_guide(ComponentDoc.names)
    render plain: [ setup, guide ].join("\n"), content_type: "text/plain"
  end

  private

  def setup
    Rails.root.join("app/views/llms/setup.md").read
  end

  def index_markdown
    components = ComponentDoc.all.map { |c| "- [#{c.title}](#{component_url(c, format: :md)}): #{c.description}" }
    <<~MARKDOWN
      #{setup.split("\n## ").first.strip}

      ## Docs

      - [Full reference](#{llms_full_url}): setup, the rules for building UI with the kit, and every component with examples, in one file
      - [Getting started](#{docs_url}): install the gem and add components
      - [Build with AI](#{doc_url("ai")}): how agents get the kit's context in an app
      - [Namespacing](#{doc_url("namespacing")})
      - [Theming](#{doc_url("theming")})
      - [Icons](#{doc_url("icons")})
      - [Lookbook](#{doc_url("lookbook")})
      - [Release notes](#{doc_url("releases")}): what each version added, changed and fixed, and what to re-run when upgrading

      ## Charts

      - [Overview](#{charts_url}): line, bar, pie and donut charts, their data, formats, colours and accessibility
      - [Line chart](#{chart_doc_url("line")}): change over time
      - [Bar chart](#{chart_doc_url("bar")}): comparing categories
      - [Stacked bar chart](#{chart_doc_url("stacked_bar")}): a total split into its parts
      - [Pie chart](#{chart_doc_url("pie")}): one total split into a few parts, at a glance
      - [Donut chart](#{chart_doc_url("donut")}): a pie with the total in its middle

      ## Components

      #{components.join("\n")}
    MARKDOWN
  end
end
