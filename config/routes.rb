Positronic::Application.routes.draw do
  root :to => 'home#index'
  resources :pages do
    member do
      get :traffic_chart
    end
    collection do
      get :panda_impact_summary
    end
  end
end
