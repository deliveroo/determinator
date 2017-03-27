# Determinator

A gem that works with [Florence](https://github.com/deliveroo/actor-tracking) to deterministically calculate whether an actor (a customer, rider, restaurant or employee) should have a feature flag turned on or off, or which variant they should see in an experiment.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'determinator'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install determinator

## Usage

### Initialize

Initialise a Determinator instance for your app with details of where the source data comes from and how it should be cached:

```ruby
App.determinator = Determinator.configure(
  bootstrap_url: "https://ats.deliveroo.net/",
  storage: Determinator::Storage::Redis.new(redis_connection),
  retrieval: Determinator::Retrieval::Routemaster.new,
)
# => #<Determinator::Control>
```

Once initialized it will keep itself up to date, you can just query it for determination arbitration:

```ruby
App.determinator.for_actor(id: 1, guid: 123).which_variant(123)
# => "aubergine"

arnie = App.determinator.for_actor(id: 1, guid: 123, constraints: { country: 'uk' })
# => #<Determinator::ActorControl id: 1, guid: 123, constraints: { country: 'uk'}>

arnie.which_variant(456)
# => false

arnie.show_feature?(78)
# => true
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/determinator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

