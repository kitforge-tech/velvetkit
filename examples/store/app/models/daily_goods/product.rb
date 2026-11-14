module DailyGoods
  # The shop's catalogue. Kept in code: the example has no database.
  Product = Data.define(:name, :category, :colour, :price, :in_stock, :image, :alt) do
    def self.all = DailyGoods::Product::ALL

    def self.find(slug) = DailyGoods::Product::ALL.find { |product| product.slug == slug }

    def slug = name.parameterize

    def to_param = slug

    # The words on the product page: size, a description and the three
    # sections under it.
    def info = DailyGoods::Product::INFO.fetch(slug)

    # A second photo for the gallery, shared by the category: a swatch,
    # a bathroom, a fabric.
    def detail_image = "daily_goods/details/#{category}.jpg"

    # Four others: the same category first, then whatever's in stock.
    # Things a shopper can filter by, beyond category and colour.
    def features = info[:features]

    # The average of the shop's own reviews, or nil with none.
    def rating
      reviews = DailyGoods::Review::ALL.select { |review| review.product == slug }
      DailyGoods::Review.average(reviews) if reviews.any?
    end

    def related
      others = DailyGoods::Product::ALL - [ self ]
      (others.select { |other| other.category == category } + others.select(&:in_stock)).uniq.first(4)
    end
  end

  Product::ALL = [
    Product.new("Repair Serum", "skincare", "black", 38, true, "daily_goods/products/serum.jpg", "Black and white pump bottle on a brown backdrop"),
    Product.new("Hand Cream", "skincare", "white", 16, true, "daily_goods/products/hand-cream.jpg", "White tube beside its cap on a peach block"),
    Product.new("Night Balm", "skincare", "black", 42, true, "daily_goods/products/night-balm.jpg", "Black jar with a blank white label on a shelf"),
    Product.new("Body Wash", "body", "white", 18, true, "daily_goods/products/body-wash.jpg", "White pump bottle on folded brown cloth"),
    Product.new("Bath Salts", "body", "white", 22, true, "daily_goods/products/bath-salts.jpg", "White jar with a screw lid on a beige backdrop"),
    Product.new("Citrus Soap", "body", "orange", 12, false, "daily_goods/products/citrus-soap.jpg", "Orange carton on white discs against a teal wall"),
    Product.new("Canvas Tote", "everyday", "tan", 24, true, "daily_goods/products/tote.jpg", "Tan tote bag against a pale grey wall"),
    Product.new("Cotton Tee", "everyday", "white", 28, false, "daily_goods/products/tee.jpg", "Plain white T-shirt on a wooden hanger"),
    Product.new("Steel Flask", "everyday", "green", 32, true, "daily_goods/products/flask.jpg", "Matte green water bottle on a white table")
  ].freeze

  # Filterable features, with their labels.
  Product::FEATURES = { "vegan" => "Vegan", "fragrance-free" => "Fragrance-free", "plastic-free" => "Plastic-free", "gift-ready" => "Gift-ready" }.freeze

  Product::INFO = {
    "repair-serum" => {
      size: "30 ml", features: %w[vegan fragrance-free], detail_alt: "A smear of white cream on a pale background",
      description: "A light serum for skin that's tired, dry or just back from a cold walk. It sinks in fast and leaves nothing sticky behind.",
      details: "Niacinamide, panthenol and squalane in a water-light base. No added fragrance.",
      use: "Two pumps on clean skin, morning and night, before cream."
    },
    "hand-cream" => {
      size: "75 ml", features: %w[vegan gift-ready], detail_alt: "A smear of white cream on a pale background",
      description: "A rich cream that soaks in before you reach for your phone. Small enough for a coat pocket.",
      details: "Shea butter, glycerin and oat. A soft scent of fig leaf.",
      use: "A pea-sized amount after washing your hands, as often as you like."
    },
    "night-balm" => {
      size: "50 ml", features: %w[fragrance-free], detail_alt: "A smear of white cream on a pale background",
      description: "A thick balm that does its work while you sleep. Wake up to skin that feels soft, not greasy.",
      details: "Ceramides, squalane and evening primrose oil. No added fragrance.",
      use: "Warm a small scoop between your fingers and press onto clean skin at night."
    },
    "body-wash" => {
      size: "300 ml", features: %w[vegan], detail_alt: "A pale green bathroom with a round mirror and white towels",
      description: "A gentle wash that lathers well and rinses clean, with a fresh cedar scent that lasts the morning.",
      details: "Coconut-based cleansers, aloe and cedarwood oil. Soap-free.",
      use: "Work into a lather on wet skin and rinse."
    },
    "bath-salts" => {
      size: "400 g", features: %w[vegan plastic-free gift-ready], detail_alt: "A pale green bathroom with a round mirror and white towels",
      description: "Mineral salts for a long soak at the end of the week. Lavender and eucalyptus, just enough to notice.",
      details: "Magnesium flakes, sea salt and essential oils.",
      use: "A handful in a warm bath. Soak for 20 minutes."
    },
    "citrus-soap" => {
      size: "120 g", features: %w[vegan plastic-free], detail_alt: "A pale green bathroom with a round mirror and white towels",
      description: "A bright bar of orange and grapefruit, cut by hand. Back next month.",
      details: "Olive and coconut oils, orange peel and grapefruit oil.",
      use: "Lather between wet hands. Keep it dry between uses and it lasts longer."
    },
    "canvas-tote" => {
      size: "38 × 42 cm", features: %w[plastic-free gift-ready], detail_alt: "Soft white fabric in loose folds",
      description: "A heavy canvas tote for the market, the library or the beach. Long handles go over a winter coat.",
      details: "100% organic cotton canvas, 12 oz. An inside pocket for keys.",
      use: "Machine wash cold, inside out. Dry flat."
    },
    "cotton-tee" => {
      size: "S to XL", features: %w[plastic-free], detail_alt: "Soft white fabric in loose folds",
      description: "A plain white tee with a little weight to it, so it hangs well and lasts. Back next month.",
      details: "100% combed cotton, 200 gsm. A regular fit.",
      use: "Machine wash at 30°C. Dry flat to keep its shape."
    },
    "steel-flask" => {
      size: "500 ml", features: %w[plastic-free gift-ready], detail_alt: "Soft white fabric in loose folds",
      description: "Keeps coffee hot for 12 hours and water cold for 24. Fits a car's cup holder.",
      details: "Double-walled stainless steel with a powder coat. A leak-proof screw lid.",
      use: "Hand wash only. Not for the microwave."
    }
  }.freeze
end
