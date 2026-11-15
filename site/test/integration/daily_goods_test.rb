require "test_helper"

# Daily Goods, the example shop mounted from examples/store.
class DailyGoodsTest < ActionDispatch::IntegrationTest
  test "the shop lists every product" do
    get "/examples/store"
    assert_response :success
    assert_select "#products article", DailyGoods::Product.all.size
    assert_select "#product-count", "9 items"
    assert_select "meta[name=robots]", count: 0
  end

  test "filters narrow and sort the products, and a filtered page isn't indexed" do
    get "/examples/store", params: { category: "skincare", sort: "price_desc" }
    assert_select "#products article h2", count: 3
    assert_equal [ "Night Balm", "Repair Serum", "Hand Cream" ], css_select("#products article h2").map(&:text)
    assert_select "meta[name=robots][content='noindex, follow']"

    get "/examples/store", params: { colours: [ "green" ], min_price: 10, max_price: 50 }
    assert_equal [ "Steel Flask" ], css_select("#products article h2").map(&:text)

    get "/examples/store", params: { category: "everyday", colours: [ "black" ] }
    assert_select "#products", /No products match/
  end

  test "the cart adds, changes and removes items" do
    get "/examples/store"
    turbo = { "Accept" => "text/vnd.turbo-stream.html" }

    post "/examples/store/cart_items", params: { product: "repair-serum" }, headers: turbo
    assert_response :success
    assert_match "Added to cart", response.body
    assert_match "Cart, 1 item", response.body
    # The card's Add to cart turns into − 1 +.
    assert_match %(<turbo-stream action="replace" target="cart-repair-serum">), response.body
    assert_match "One more Repair Serum", response.body

    get "/examples/store"
    assert_select "#cart-repair-serum [aria-label='Quantity of Repair Serum'] span", "1"
    assert_select "#cart-hand-cream button", /Add to cart/

    patch "/examples/store/cart_items/repair-serum", params: { quantity: 3 }, headers: turbo
    assert_match "Cart, 3 items", response.body
    assert_match "$114", response.body

    delete "/examples/store/cart_items/repair-serum", headers: turbo
    assert_match "Your cart is empty", response.body
    assert_match "Add Repair Serum to cart", response.body
  end

  test "a sold-out product can't be added" do
    post "/examples/store/cart_items", params: { product: "citrus-soap" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_match "Cart, 0 items", response.body
    assert_no_match "Added to cart", response.body

    get "/examples/store"
    assert_select "#cart-citrus-soap button[disabled]", "Sold out"
  end

  test "a product page shows its photos, details, reviews and related products" do
    get "/examples/store/products/repair-serum"
    assert_response :success
    assert_select "title", /\ARepair Serum · Daily Goods/
    assert_select "link[rel=canonical][href$='/examples/store/products/repair-serum']"
    assert_select "nav[aria-label] a", "Skincare"
    assert_select "h1", "Repair Serum"
    assert_select "[data-slot=gallery] img", minimum: 2
    assert_select "#cart-repair-serum button", /Add to cart/
    assert_select "#reviews li", 3
    assert_select "#reviews [role=img][aria-label='4.7 out of 5 stars']"
    assert_select "#related-heading + div article", 4
    assert_select "#related-heading + div article h3", minimum: 1

    get "/examples/store"
    assert_select "turbo-frame#products[target=_top] article a[href='/examples/store/products/repair-serum']", minimum: 1
  end

  test "an unknown product is a 404" do
    get "/examples/store/products/nope"
    assert_response :not_found
  end

  test "a review is checked, then shows for the person who wrote it" do
    turbo = { "Accept" => "text/vnd.turbo-stream.html" }
    get "/examples/store/products/night-balm"
    assert_select "#reviews li", 1

    post "/examples/store/products/night-balm/reviews", params: { review: { rating: "", author: "", body: "ok" } }, headers: turbo
    assert_response :unprocessable_entity
    assert_match %(target="review-form"), response.body
    assert_match "Choose from one to five stars.", response.body
    assert_match "at least 10 characters", response.body

    post "/examples/store/products/night-balm/reviews", params: { review: { rating: "4", author: "Alex", body: "Soaks in overnight." } }, headers: turbo
    assert_response :success
    assert_match %(target="reviews"), response.body
    assert_match "Thanks for your review", response.body

    get "/examples/store/products/night-balm"
    assert_select "#reviews li", 2
    assert_select "#reviews li", /Soaks in overnight/

    get "/examples/store/products/hand-cream"
    assert_select "#reviews li", 2
  end

  test "the front page has the shop's promises, categories, reviews, newsletter and footer" do
    get "/examples/store"
    assert_select "ul[aria-label='Why shop with us'] li", 4
    assert_select "section[aria-labelledby=categories-heading] a[href='/examples/store/?category=body#shop']"
    assert_select "section[aria-labelledby=testimonials-heading] li", 3
    assert_select "#newsletter-form input[type=email][name=email]"
    assert_select "footer nav[aria-label=Help]"
  end

  test "the newsletter checks the address and says thanks" do
    turbo = { "Accept" => "text/vnd.turbo-stream.html" }
    post "/examples/store/newsletter", params: { email: "not-an-email" }, headers: turbo
    assert_response :unprocessable_entity
    assert_match "Enter an email address", response.body

    post "/examples/store/newsletter", params: { email: "sam@example.com" }, headers: turbo
    assert_response :success
    assert_match "on the list.", response.body
  end

  test "rating and feature filters narrow the products, with a chip to undo each" do
    get "/examples/store", params: { rating: "4.5", features: %w[vegan] }
    assert_select "#products article h2", count: 3
    assert_select "#products article h2", text: "Body Wash", count: 0
    assert_select "[aria-label='Remove filter: Vegan'][href='/examples/store/?rating=4.5#shop']"
    assert_select "[aria-label='Remove filter: Rated 4.5 and up'][href='/examples/store/?features%5B%5D=vegan#shop']"

    get "/examples/store", params: { features: %w[vegan bogus], rating: "9" }
    assert_select "#products article", 5
    assert_select "[aria-label^='Remove filter']", 1
  end
end
