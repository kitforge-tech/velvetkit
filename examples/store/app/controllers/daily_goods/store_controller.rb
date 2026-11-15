module DailyGoods
  class StoreController < ApplicationController
    CATEGORIES = %w[all skincare body everyday].freeze
    COLOURS = %w[white black green tan orange].freeze
    PRICES = (10..50)
    RATINGS = { "4.5" => "4.5 and up", "4" => "4 and up" }.freeze
    SORTS = [ [ "Most popular", "popular" ], [ "Newest", "newest" ], [ "Price, low to high", "price_asc" ], [ "Price, high to low", "price_desc" ] ].freeze

    def index
      @category  = CATEGORIES.include?(params[:category]) ? params[:category] : "all"
      @sort      = SORTS.map(&:last).include?(params[:sort]) ? params[:sort] : "popular"
      @min_price = price(:min_price, PRICES.min)
      @max_price = price(:max_price, PRICES.max)
      @colours   = Array(params[:colours]).grep(String) & COLOURS
      @in_stock  = params[:in_stock].present?
      @rating    = RATINGS.key?(params[:rating]) ? params[:rating] : nil
      @features  = Array(params[:features]).grep(String) & Product::FEATURES.keys
      @products  = sorted(filtered)
      @chips     = chips
    end

    private

    # The page's query, without values left at their defaults.
    def query
      { category: (@category unless @category == "all"), sort: (@sort unless @sort == "popular"),
        min_price: (@min_price unless @min_price == PRICES.min), max_price: (@max_price unless @max_price == PRICES.max),
        colours: @colours.presence, in_stock: (1 if @in_stock), rating: @rating, features: @features.presence }.compact
    end

    # One chip per filter in use, each with the page's address without it.
    def chips
      without = ->(key, value = nil) { value ? query.merge(key => query[key] - [ value ]).compact_blank : query.except(key) }
      list = []
      list << [ @category.capitalize, without.(:category) ] if query[:category]
      list << [ "$#{@min_price} to $#{@max_price}", query.except(:min_price, :max_price) ] if query[:min_price] || query[:max_price]
      @colours.each { |colour| list << [ colour.capitalize, without.(:colours, colour) ] }
      @features.each { |feature| list << [ Product::FEATURES[feature], without.(:features, feature) ] }
      list << [ "Rated #{RATINGS[@rating]}", without.(:rating) ] if @rating
      list << [ "In stock", without.(:in_stock) ] if @in_stock
      list.map { |label, rest| { label: label, href: root_path(rest.merge(anchor: "shop")) } }
    end

    def price(key, default)
      Integer(params[key].to_s, exception: false) || default
    end

    def filtered
      Product.all.select do |product|
        (@category == "all" || product.category == @category) &&
          product.price.between?(@min_price, @max_price) &&
          (@colours.empty? || @colours.include?(product.colour)) &&
          (!@in_stock || product.in_stock) &&
          (@rating.nil? || product.rating.to_f >= @rating.to_f) &&
          (@features - product.features).empty?
      end
    end

    def sorted(products)
      case @sort
      when "newest" then products.reverse
      when "price_asc" then products.sort_by(&:price)
      when "price_desc" then products.sort_by { |product| -product.price }
      else products
      end
    end
  end
end
