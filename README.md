# Determinator

A gem that works with [Florence](https://github.com/deliveroo/actor-tracking) to deterministically calculate whether an actor (a customer, rider, restaurant or employee) should have a feature flag turned on or off, or which variant they should see in an experiment.

![Determinator](docs/img/determinator.jpg)

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

Feature flags and Experiments can be configured to have string based constraints. When the experiment's _constraints_ do not match the given actor's _properties_, the flag or experiment will always be off. When they match the rollout specified by the feature will be applied.

Constraints must be strings, what matches and doesn't is configurable after-the-fact within Florence.

```ruby
# Constraints
variant = determinator.which_variant(
  :my_experiment_name,
  properties: {
    country_of_first_order: current_user.orders.first.country.tld,
  }
)
```

## Installation

Determinator requires your application to be subscribed to the a `features` topic via Routemaster.

The drain must expire the routemaster cache on receipt of events, `Routemaster::Drain::CacheBusting.new` or better.

Check the example Rails app in `examples` for more information on how to make use of this gem.

```
# config/initializers/determinator.rb

require 'determinator/retrieve/routemaster'
Determinator.configure(
  retrieval: Determinator::Retrieve::Routemaster.new(
    discovery_url: 'https://florence.dev/'
    retrieval_cache: ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute)
  )
)
```

### Retrieval Cache

Determinator will function fully without a retrieval_cache set, although Determinator will produce 1 Redis query for every determination. By setting a `retrieval_cache` as an instance of `ActiveSupport::Cache::MemoryStore` (or equivalent) this can be reduced per application instance. This cache is not expired so *must* have a `expires_in` set, ideally to a short amount of time.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/deliveroo/determinator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

Any PR should include a new section at the top of the `CHANGELOG.md` (if it doesn't exist) called 'Unreleased' of a similar format to the lines below. Upon release, this will be used to detail what has been added.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
