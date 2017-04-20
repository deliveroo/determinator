# Rails and Determinator example

This example Rails app has been configured so that Determinator is correctly configured, and (with an instance of the Actor Tracking Service and Routemaster running alongside) it will correctly determine feature rollout and experiment variant selection.

## Points of interest

### `config/initializers/determinator.rb`

This file sets up the singleton Determinator instance for the application.

### `config/routes.rb`

Using Determinator with Routemaster means that you must expose an endpoint to be informed of changes to Features. Determinator makes it easy to set this up with the `#configure_rails_router` helper method.

### `Procfile`

Bear in mind that, because routemaster depends on background workers to populate the cache, Sidekiq (or Resque) must be running alongside the app.

### `app/controllers/index_controller.rb`

An example of how Determinator can be used for feature flags.

### `app/controllers/application_controller.rb`

An example of how a GUID could be assigned to every visitor to the site. Storing this in the session means it will be reset upon log out.

The `determinator` method memoizes the instance of the `ActorControl` helper class for ease of use throughout this request.

### `config/application.rb`

Ensure you've required the job runner backend appropriate for your set up. Routemaster Drain currently supports Sidekiq and Resque.

### `config/sidekiq.yml`

This example uses Sidekiq as the background processor, ensure you've set it up correctly for notifications to cache in the background.
