module DailyGoods
  # Adds, changes and removes cart lines. Answers with Turbo Streams that
  # refresh the header count and the cart sheet; without Turbo, goes back.
  class CartItemsController < ApplicationController
    before_action :set_product

    def create
      if @product.in_stock
        cart.add(@product)
        @added = @product
      end
      respond
    end

    def update
      cart.set(@product, params[:quantity])
      respond
    end

    def destroy
      cart.set(@product, 0)
      respond
    end

    private

    def set_product
      @product = Product.find(params[:id] || params[:product]) or head :not_found
    end

    def respond
      respond_to do |format|
        format.turbo_stream { render "daily_goods/cart_items/update" }
        format.html { redirect_back_or_to root_path }
      end
    end
  end
end
