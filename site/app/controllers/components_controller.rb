class ComponentsController < ApplicationController
  layout "docs"

  def index
    @components = ComponentDoc.all
  end

  def show
    @component = ComponentDoc.find(params[:id])

    respond_to do |format|
      format.html
      format.md { render plain: @component.page_markdown, content_type: "text/markdown" }
    end
  end
end
