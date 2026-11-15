module DailyGoods
  class ApplicationController < ActionController::Base
    helper DailyGoods::StoreHelper
    helper_method :cart

    private

    def cart = @cart ||= Cart.new(session)
  end
end
