Pinhole::Engine.routes.draw do
  root "photos#index"
  get "favourites", to: "photos#favourites", as: :favourites
  get "archive", to: "photos#archive", as: :archive
  get "bin", to: "photos#bin", as: :bin
  get "search", to: "photos#search", as: :search
  resources :albums, only: %i[index show create destroy]
  resources :places, only: %i[index show]
  # What the selection bar's buttons do to the photos chosen.
  resource :selection, only: :create
  patch "photos/:id/favourite", to: "favourites#update", as: :photo_favourite
end
