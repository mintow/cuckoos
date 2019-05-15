resources :projects do
  resources :cuckoos do
    post 'update_trigger_points', :on => :collection
    post '/update_trigger_points', :to => 'cuckoos#update_trigger_points'
    get '/send', :to => 'cuckoos#send_now', as: 'send'
    post '/edit', :to => 'cuckoos#edit'
  end
end

