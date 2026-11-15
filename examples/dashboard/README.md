# Helio

An example dashboard built with VelvetKit: the admin side of a small, made-up
software company. Customers to search, filter, sort, choose and act on in
bulk, a page for each with its invoices, activity and notes, and an overview
whose numbers change with the period. It runs inside the docs site at
[/examples/dashboard](https://velvetkit.com/examples/dashboard), but its code
lives here, apart from the docs.

It's a Rails engine, `Helio`, mounted by `site/config/routes.rb`. It has no
database: 140 customers are made up from a fixed seed in
`app/models/helio/customer.rb`, and the overview's numbers are worked out from
them in `app/models/helio/metrics.rb`, so they agree with each other. What a
visitor changes (a plan, a trial extended, a subscription cancelled, a note)
is kept in their session by `app/models/helio/workspace.rb`.

## Running it

Start the docs site and open <http://localhost:3000/examples/dashboard>:

    cd site && bin/dev

## What's where

- **Components:** it uses the site's copy of the kit (`UI::`): the sidebar,
  `Table` with sortable headers and rows to select, `SelectionBar`,
  `Pagination`, `Chart`, `Tabs`, `Timeline`, `Menu` and `Command`.
- **Theme:** `app/assets/stylesheets/helio/theme.css`. The site builds the
  dashboard's own stylesheet from `site/app/assets/stylesheets/helio.tailwind.css`.
- **JavaScript:** `app/assets/javascripts/helio/dashboard.js` sends a filter
  form as soon as it changes. Everything else is the kit's.
