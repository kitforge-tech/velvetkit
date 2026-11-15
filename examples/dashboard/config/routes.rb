Helio::Engine.routes.draw do
  root "overview#show"
  resources :customers, only: %i[index show update] do
    resources :notes, only: :create
    # What the selection bar's buttons do to the customers chosen.
    post :bulk, on: :collection
  end
end
