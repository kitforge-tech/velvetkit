module DailyGoods
  class ProductsController < ApplicationController
    def show
      @product = Product.find(params[:id]) or raise ActionController::RoutingError, "No product #{params[:id]}"
      @reviews = Review.for(@product, session)
    end
  end
end
