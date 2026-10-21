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
      - [Lookbook](#{doc_url("lookbook")})

      ## Components

      #{components.join("\n")}
    MARKDOWN
  end
end
