require 'routemaster/drain/cache_busting'
Rails.application.routes.draw do
  root to: 'index#show'
  mount Routemaster::Drain::CacheBusting.new, at: ENV.fetch('ROUTEMASTER_CALLBACK_URL')
end
