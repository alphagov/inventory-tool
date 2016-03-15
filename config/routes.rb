Rails.application.routes.draw do
  root to: 'inventories#index'

  resources :inventories, only: [:index, :create, :update, :destroy]

  mount GovukAdminTemplate::Engine, at: "/style-guide" if Rails.env.development?
end
