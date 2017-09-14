#Sets up the routemaster client and subscribes to the 'features' topic
Routemaster::Client.subscribe(
  topics: %w[
    features
  ],
  callback: ENV.fetch('ROUTEMASTER_CALLBACK_URL'),
  uuid: ENV.fetch('ROUTEMASTER_DRAIN_TOKENS'),
  max: ENV.fetch('ROUTEMASTER_DRAIN_BATCH_SIZE', 1).to_i
)
