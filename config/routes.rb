Rails.application.routes.draw do
  resources :messages
  post "messages/callback" => "messages#callback"
  root "messages#index"
end
