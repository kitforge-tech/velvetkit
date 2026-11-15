module DailyGoods
  # Reviews on the product page. The ones below are made up for the example;
  # reviews people write stay in their own session, so nobody else sees them.
  Review = Data.define(:product, :author, :rating, :title, :body, :date) do
    # A product's reviews, newest first: the visitor's own, then the rest.
    def self.for(product, session)
      own = Array(session[:reviews]).filter_map do |review|
        next unless review["product"] == product.slug

        new(product.slug, review["author"], review["rating"], review["title"], review["body"], Date.parse(review["date"]))
      end
      (own + DailyGoods::Review::ALL.select { |review| review.product == product.slug }).sort_by(&:date).reverse
    end

    def self.average(reviews) = reviews.sum(&:rating).fdiv(reviews.size).round(1)

    # Keeps the last few in the session, which is a cookie with little room.
    def self.keep(review, session)
      session[:reviews] = (Array(session[:reviews]) + [ review.to_h.transform_keys(&:to_s).merge("date" => review.date.iso8601) ]).last(DailyGoods::Review::MAX_KEPT)
    end
  end

  Review::MAX_KEPT = 3

  Review::ALL = [
    Review.new("repair-serum", "Maya", 5, "My skin drinks it", "Two weeks in and my cheeks aren't flaky any more. No smell, which I love.", Date.new(2026, 10, 30)),
    Review.new("repair-serum", "Tom", 4, "Good, a bit small", "Works well under sunscreen. I wish the bottle were bigger for the price.", Date.new(2026, 10, 12)),
    Review.new("repair-serum", "Priya", 5, "Bought a second one", "Light, fast, and my skin feels calmer. The pump gives exactly enough.", Date.new(2026, 9, 21)),
    Review.new("hand-cream", "Jonas", 5, "Not greasy at all", "I can type straight after putting it on. The fig scent is lovely.", Date.new(2026, 11, 2)),
    Review.new("hand-cream", "Ana", 4, "Lives in my bag", "Does the job in winter. The tube is a little stiff when it's cold.", Date.new(2026, 10, 18)),
    Review.new("night-balm", "Lena", 5, "Worth it", "Thick, but it melts in. My skin is softer in the morning.", Date.new(2026, 10, 25)),
    Review.new("body-wash", "Sam", 4, "Nice cedar smell", "Lathers well and doesn't dry me out. Would buy a refill pouch if there was one.", Date.new(2026, 10, 8)),
    Review.new("bath-salts", "Noor", 5, "Sunday ritual", "Just enough scent. The jar looks good on the shelf too.", Date.new(2026, 10, 3)),
    Review.new("canvas-tote", "Ben", 5, "Properly sturdy", "Carried six bottles of milk home in it. The inside pocket is handy.", Date.new(2026, 11, 5)),
    Review.new("canvas-tote", "Ida", 4, "Great size", "Fits a laptop and lunch. The handles are long enough to go on a shoulder with a coat.", Date.new(2026, 9, 30)),
    Review.new("steel-flask", "Ravi", 5, "Still hot at 4 pm", "Filled it at 7 and the tea was still too hot at lunch. No leaks in my bag.", Date.new(2026, 10, 20))
  ].freeze
end
