module DailyGoods
  # The newsletter form. Checks the address and says thanks; nothing is stored
  # or sent, since the shop is an example.
  class NewslettersController < ApplicationController
    def create
      @email = params[:email].to_s.strip.first(254)
      @error = "Enter an email address like you@example.com." unless @email.match?(URI::MailTo::EMAIL_REGEXP)

      respond_to do |format|
        format.turbo_stream { render :create, status: (@error ? :unprocessable_entity : :ok) }
        format.html { redirect_to root_path, alert: @error }
      end
    end
  end
end
