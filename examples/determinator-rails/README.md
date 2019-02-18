# Rails and Determinator example

This example Rails app has been configured so that Determinator is correctly configured, and (with an instance of the Actor Tracking Service) it will correctly determine feature rollout and experiment variant selection.

## Points of interest

### `config/initializers/determinator.rb`

This file sets up the singleton Determinator instance for the application.

### `app/controllers/index_controller.rb`

An example of how Determinator can be used for feature flags and experiments.

### `app/controllers/application_controller.rb`

An example of how a GUID could be assigned to every visitor to the site. Storing this in the session means it will be reset upon log out.

The `determinator` method memoizes the instance of the `ActorControl` helper class for ease of use throughout this request.
