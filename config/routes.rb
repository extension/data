Positronic::Application.routes.draw do
  root :to => 'home#index'
  resources :pages
end
