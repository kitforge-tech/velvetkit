Helio::Engine.routes.draw do
  root "overview#show"
  resources :customers, only: :index
end
