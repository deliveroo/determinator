require 'determinator/retrieve/routemaster'

Determinator.configure(
  retrieval: Determinator::Retrieve::Routemaster.new(
    discovery_url: 'https://florence.dev/'
    retrieval_cache: ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute)
  )
  # The following would allow tracking of errors in NewRelic
  # errors: -> error { NewRelic::Agent.notice_error(error) }
)
