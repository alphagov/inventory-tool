Rails.application.routes.draw do
  
  root to: 'inventories#index'

  # get 'inventories', to: 'inventories#index'
  resources :inventories, only: [:index, :create, :update, :destroy]
  resources :activity_logs, only: [:index, :show]

  get 'errors', to: 'errors#index'


  if Rails.env.development?
    mount GovukAdminTemplate::Engine, at: "/style-guide"
  end
end
