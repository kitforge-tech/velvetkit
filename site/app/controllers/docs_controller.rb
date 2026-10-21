class DocsController < ApplicationController
  # Guide pages, in the order the sidebar lists them.
  PAGES = {
    "getting_started" => "Getting started",
    "ai" => "Build with AI",
    "namespacing" => "Namespacing",
    "theming" => "Theming and dark mode",
    "lookbook" => "Lookbook"
  }.freeze

  layout "docs"

  def show
    @page = params[:page]
    render @page
  end
end
