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
    "releases" => "Release notes"
  }.freeze

  # Listed under Forms in the sidebar rather than Guides.
  FORM_PAGES = %w[forms].freeze

  layout "docs"

  def show
    @page = params[:page]
    render @page
  end
end
