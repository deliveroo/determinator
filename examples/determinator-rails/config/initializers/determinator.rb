require 'determinator/retrieve/routemaster'

Determinator.configure(
  retrieval: Determinator::Retrieve::Routemaster.new(
    discovery_url: 'https://florence.dev/'
  )
)
