require 'determinator/retrieve/dynaconf'
require 'active_support/cache'

retrieval = Determinator::Retrieve::Dynaconf.new(base_url: 'http://localhost:2345', service_name: 'determinator-rails')
feature_cache = Determinator::Cache::FetchWrapper.new(
  ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute)
)
Determinator.configure(retrieval: retrieval, feature_cache: feature_cache)

Determinator.on_error do |error|
  # NewRelic::Agent.notice_error(error)
end

Determinator.on_missing_feature do |feature_name|
  # STATSD.increment 'determinator.missing_feature', tags: ["feature:#{name}"]
end

Determinator.on_determination do |id, guid, feature, determination|
  if feature.experiment? && determination != false
    puts "TODO: Track that user #{id}/#{guid} saw the #{determination} variant of '#{feature.name}' for analysis"
  end
end
