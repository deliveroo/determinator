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

Feature flags and Experiments can be configured to have string based constraints. When the strings required for the experiment do not match, the user will _never_ see the flag or the experiment, when they match, then the rollout specified by the feature will be applied.

Constraints must be strings, what matches and doesn't is configurable after-the-fact within Florence.

```ruby
# Constraints
variant = determinator.which_variant(
  :my_experiment_name,
  constraints: {
    country_of_first_order: current_user.orders.first.country.tld,
  }
)
```

## Installation

Check the example Rails app in `examples` for more information on how to make use of this gem.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/deliveroo/determinator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

Any PR should include a new section at the top of the `CHANGELOG.md` (if it doesn't exist) called 'Unreleased' of a similar format to the lines below. Upon release, this will be used to detail what has been added.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

