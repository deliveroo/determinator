# Determinator

A gem that works with _Florence_ to deterministically calculate whether an **actor** should have a feature flag turned on or off, or which variant they should see in an experiment.

![Determinator](docs/img/determinator.jpg)

Useful documentation:

- [Terminology and Background](docs/background.md)
- [Local development](docs/local_development.md)
- [Example implemention in Rails](examples/determinator-rails)

## Usage

Once [set up](#installation), determinator can be used to determine whether a **feature flag** or **experiment** is on or off for the current user and, for experiments, which **variant** they should see.

```ruby
# Feature flags
if determinator.feature_flag_on?(:my_feature_name)
  # Show the feature
end

# Experiments
case determinator.which_variant(:my_experiment_name)
when 'control'
  # Do nothing different
when 'sloths'
  # Show some sloth pictures
when 'velociraptors'
  # RUN!
end
```

Feature flags and experiments can be targeted to specific actors by specifying actor properties (which must match the constraints defined in the feature).

```ruby
# Targeting specific actors
variant = determinator.which_variant(
  :my_experiment_name,
  properties: {
    employee: current_user.employee?
  }
)
```

Writing tests? Check out the [Local development](docs/local_development.md) docs to see examples of `RSpec::Determinator` to help you mock your Feature Flags and Experiments.

## Installation

Determinator requires your application to be subscribed to the a `features` topic via Routemaster.

The drain must expire the routemaster cache on receipt of events, `Routemaster::Drain::CacheBusting.new` or better.

Check the example Rails app in `examples` for more information on how to make use of this gem.

```
# config/initializers/determinator.rb

require 'determinator/retrieve/routemaster'
Determinator.configure(
  retrieval: Determinator::Retrieve::Routemaster.new(
    discovery_url: 'https://flo.dev/'
    retrieval_cache: ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute)
  ),
  errors: -> error { NewRelic::Agent.notice_error(error) },
  missing_features: -> feature_name { STATSD.increment 'determinator.missing_feature', tags: ["feature:#{name}"] }
)
```

### Retrieval Cache

Determinator will function fully without a retrieval_cache set, although Determinator will produce 1 Redis query for every determination. By setting a `retrieval_cache` as an instance of `ActiveSupport::Cache::MemoryStore` (or equivalent) this can be reduced per application instance. This cache is not expired so *must* have a `expires_in` set, ideally to a short amount of time.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/deliveroo/determinator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

Any PR should include a new section at the top of the `CHANGELOG.md` (if it doesn't exist) called 'Unreleased' of a similar format to the lines below. Upon release, this will be used to detail what has been added.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
