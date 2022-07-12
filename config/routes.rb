Rails.application.routes.draw do
  resources :applications, param: :token do
    resources :chats, param: :number do
      resources :messages
    end
  end
end