DailyGoods::Engine.routes.draw do
  root "store#index"
  resources :products, only: :show do
    resources :reviews, only: :create
  end
  resources :cart_items, only: %i[create update destroy]
  resource :newsletter, only: :create
end
