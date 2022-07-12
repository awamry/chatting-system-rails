Rails.application.routes.draw do
  resources :applications, param: :token do
    resources :chats do
      resources :messages
    end
  end
end