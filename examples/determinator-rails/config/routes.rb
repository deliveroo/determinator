Rails.application.routes.draw do
  root to: 'index#show'

  # DETERMINATOR: Make sure the routemaster routes are mapped to the containing app.
  Determinator.instance.retrieval.configure_rails_router(self)
end
