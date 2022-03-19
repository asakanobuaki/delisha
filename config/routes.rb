Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get 'hello/index'
  post 'callback', to: 'line_bot#callback'
end
