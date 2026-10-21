Rails.application.routes.draw do
  root "pages#home"

  # For AI agents: https://llmstxt.org
  get "llms.txt", to: "llms#index", as: :llms, format: false
  get "llms-full.txt", to: "llms#full", as: :llms_full, format: false

  get "docs", to: "docs#show", as: :docs, defaults: { page: "getting_started" }
  get "docs/components", to: "components#index", as: :components
  get "docs/components/:id", to: "components#show", as: :component, constraints: { format: /html|md/ }
  get "docs/:page", to: "docs#show", as: :doc, constraints: { page: Regexp.union(DocsController::PAGES.keys) }

  get "demo/rows", to: "demo_rows#index", as: :demo_rows, defaults: { format: :json }

  mount Lookbook::Engine, at: "/lookbook"

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "up" => "rails/health#show", as: :rails_health_check
end
