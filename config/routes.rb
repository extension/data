Positronic::Application.routes.draw do
  root :to => 'home#index'
  resources :pages, :only => [:index, :show] do
    member do
      get :traffic_chart
    end
    collection do
      get :panda_impact_summary
      get :groups
    end
  end
  
  resources :groups, :only => [:index, :show] do
    member do
      get :pages
    end
  end
end
