# Daily Goods

An example shop built with VelvetKit: a product grid with filters and
sorting, and a cart in a side sheet, all without a page reload. It runs
inside the docs site at [/examples/store](https://velvetkit.com/examples/store),
but its code lives here, apart from the docs.

It's a Rails engine, `DailyGoods`, mounted by `site/config/routes.rb`. It has
no database: the products are in `app/models/daily_goods/product.rb` and the
cart is kept in the session.

## Running it

Start the docs site and open <http://localhost:3000/examples/store>:

    cd site && bin/dev

## What's where

- **Components:** it uses the site's copy of the kit (`UI::`), so it adds no
  component code of its own.
- **Theme:** `app/assets/stylesheets/daily_goods/theme.css` holds the lilac
  theme. The site builds the shop's own stylesheet from
  `site/app/assets/stylesheets/daily_goods.tailwind.css`, so the shop's
  colours and fonts never reach the docs.
- **JavaScript:** `app/assets/javascripts/daily_goods/shop.js` sends the
  filters as they change and the cart's forms one after another.
- **Photos:** from Unsplash; see [PHOTOS.md](PHOTOS.md).
