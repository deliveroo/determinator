require 'determinator/retrieve/routemaster'
require 'determinator/cache/active_support_memory_store'

retrieval = Determinator::Retrieve::Routemaster.new(discovery_url: 'https://flo.dev/')
Determinator.configure(retrieval: retrieval)
Determinator.retrieval_cache = Determinator::Cache::ActiveSupportMemoryStore.new(expires_in: 1.minute)

Determinator.on_error do |error|
  # NewRelic::Agent.notice_error(error)
end

Determinator.on_missing_feature do |feature_name|
  # STATSD.increment 'determinator.missing_feature', tags: ["feature:#{name}"]
end

Determinator.on_determination do |id, guid, feature, determination|
  if feature.experiment? && determination !== false
    # YourTrackingSolution.record_variant_viewing(
    #   user_id: id,
    #   experiment_name: feature.name,
    #   variant: determination
    # )
  end
end
