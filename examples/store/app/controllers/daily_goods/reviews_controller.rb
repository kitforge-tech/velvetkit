module DailyGoods
  # A review written on the product page. It's kept in the visitor's session,
  # so it shows for them alone: the example has no database to share it.
  class ReviewsController < ApplicationController
    def create
      @product = Product.find(params[:product_id]) or raise ActionController::RoutingError, "No product"
      @draft = draft
      @errors = errors_for(@draft)

      if @errors.empty?
        Review.keep(Review.new(@product.slug, @draft[:author], @draft[:rating], @draft[:title], @draft[:body], Date.current), session)
        @reviews = Review.for(@product, session)
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to product_path(@product, anchor: "reviews") }
        end
      else
        respond_to do |format|
          format.turbo_stream { render :create, status: :unprocessable_entity }
          format.html { redirect_to product_path(@product, anchor: "reviews"), alert: @errors.values.first }
        end
      end
    end

    private

    def draft
      review = params.fetch(:review, {})
      { rating: Integer(review[:rating].to_s, exception: false),
        author: review[:author].to_s.strip.first(40),
        title: review[:title].to_s.strip.first(80),
        body: review[:body].to_s.strip.first(500) }
    end

    def errors_for(draft)
      errors = {}
      errors[:rating] = "Choose from one to five stars." unless (1..5).cover?(draft[:rating])
      errors[:author] = "Add a name, or just your initials." if draft[:author].blank?
      errors[:body] = "Say a little about it: at least 10 characters." if draft[:body].length < 10
      errors
    end
  end
end
