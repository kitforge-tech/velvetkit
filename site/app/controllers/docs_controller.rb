class DocsController < ApplicationController
  # Guide pages, in the order the sidebar lists them.
  PAGES = {
    "getting_started" => "Getting started",
    "ai" => "Build with AI",
    "namespacing" => "Namespacing",
    "theming" => "Theming and dark mode",
    "icons" => "Icons",
    "lookbook" => "Lookbook",
    "forms" => "Building forms",
    "upgrading" => "Upgrading",
    "releases" => "Release notes"
  }.freeze

  # Pages with an "Ask AI" menu: copy as Markdown, view it, open it in an
  # assistant, and what to ask about each.
  ASK_AI = {
    "upgrading" => "help me upgrade the VelvetKit components in my Rails app",
    "releases" => "tell me what changed in VelvetKit, and what my Rails app needs to do about it"
  }.freeze

  # Listed under Forms in the sidebar rather than Guides.
  FORM_PAGES = %w[forms].freeze

  layout "docs"

  def show
    @page = params[:page]

    respond_to do |format|
      format.html do
        @markdown = markdown if ASK_AI.key?(@page)
        render @page
      end
      format.md { render plain: markdown, content_type: "text/markdown" }
    end
  end

  private

  # The release notes come straight from CHANGELOG.md; every other guide is
  # its own page turned into Markdown, so the two can't disagree.
  def markdown
    if @page == "releases"
      upgrading = "Moving up a minor version? [Upgrading](#{doc_url('upgrading', format: :md)}) has every step in one place."
      return "# VelvetKit release notes\n\n#{upgrading}\n\n#{ReleaseNotes.markdown}\n"
    end

    PageMarkdown.from_html(render_to_string(@page, layout: false, formats: [ :html ]), base_url: request.base_url)
  end
end
