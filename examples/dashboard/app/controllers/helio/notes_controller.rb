module Helio
  class NotesController < ApplicationController
    def create
      customer = workspace.customer(params[:customer_id]) or raise ActionController::RoutingError, "No customer"
      text = params[:text].to_s.strip
      if text.length.between?(2, 280)
        workspace.add_note(customer, text)
        redirect_to customer_path(customer, tab: "notes"), notice: "Note saved."
      else
        redirect_to customer_path(customer, tab: "notes"), alert: "A note is 2 to 280 characters."
      end
    end
  end
end
