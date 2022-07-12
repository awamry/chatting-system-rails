Rails.application.routes.draw do
  resources :applications, param: :token do
    resources :chats, param: :number do
      resources :messages, param: :number
      get 'body/search', to: 'messages#search_message_body'
    end
  end
end