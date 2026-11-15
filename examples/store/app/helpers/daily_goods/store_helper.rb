module DailyGoods
  # The store's navigation, shared by the header, the phone menu, the
  # category tiles and the footer.
  module StoreHelper
    def shop_links
      [
        { title: "All products", href: root_path, icon: "layout-grid", description: "Everything in the store." },
        { title: "New in", href: root_path(sort: "newest"), icon: "sparkles", description: "Just arrived this month." },
        { title: "In stock", href: root_path(in_stock: 1), icon: "package-check", description: "Ready to ship today." }
      ]
    end

    def shop_categories
      [
        { title: "Skincare", href: root_path(category: "skincare"), image: "daily_goods/products/serum.jpg", description: "Serums and balms" },
        { title: "Body", href: root_path(category: "body"), image: "daily_goods/products/body-wash.jpg", description: "Washes and salts" },
        { title: "Everyday", href: root_path(category: "everyday"), image: "daily_goods/products/tote.jpg", description: "Totes and flasks" }
      ]
    end

    # What the shop promises, under the banner and in the footer.
    def shop_promises
      [
        { icon: "truck", title: "Free shipping", text: "On orders over $50" },
        { icon: "rotate-ccw", title: "30-day returns", text: "Unopened, no questions" },
        { icon: "shield-check", title: "Secure checkout", text: "Encrypted payments" },
        { icon: "leaf", title: "Small batches", text: "Made in limited runs" }
      ]
    end
  end
end
