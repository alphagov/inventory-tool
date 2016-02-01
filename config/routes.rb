Rails.application.routes.draw do
  root to: 'inventories#index'

  resources :inventories, only: [:index, :create, :update, :destroy]

  if Rails.env.development?
    mount GovukAdminTemplate::Engine, at: "/style-guide"
  end
end
