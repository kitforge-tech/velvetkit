module DailyGoods
  # A cart kept in the session as { slug => quantity }.
  class Cart
    Line = Data.define(:product, :quantity) do
      def total = product.price * quantity
    end

    MAX_QUANTITY = 9

    def initialize(session)
      @items = (session[:cart] ||= {})
    end

    def lines
      @items.filter_map do |slug, quantity|
        product = Product.find(slug)
        Line.new(product, quantity) if product
      end
    end

    def add(product) = set(product, quantity_of(product) + 1)

    def set(product, quantity)
      quantity = quantity.to_i.clamp(0, MAX_QUANTITY)
      quantity.zero? ? @items.delete(product.slug) : @items[product.slug] = quantity
    end

    def quantity_of(product) = @items.fetch(product.slug, 0)

    def count = lines.sum(&:quantity)

    def subtotal = lines.sum(&:total)

    def empty? = lines.empty?
  end
end
