# Determinator

A gem that works with Florence to deterministically calculate whether an **actor** should have a feature flag turned on or off, or which variant they should see in an experiment. Florence's UI is currently hosted within [actor-tracking](https://github.com/deliveroo/actor-tracking).

You can make changes to your feature flags and experiments within Florence. If you work at Deliveroo you can find Florence UI at: https://actor-tracking.deliveroo.net/florence

![Arnold Schwarzenegger might say "Come with me if you want to experiment" if he played The Determinator instead of The Terminator.](docs/img/determinator.jpg)

---

#### Useful documentation

- [Terminology and Background](docs/background.md)
- [Local development](docs/local_development.md)
- [Example implemention in Rails](examples/determinator-rails)

#### Getting help

For Deliveroo Employees:

- Many people contribute to Determinator and Florence. We hang out in [this Slack channel](https://deliveroo.slack.com/app_redirect?channel=florence_wg)
- [This JIRA board](https://deliveroo.atlassian.net/secure/RapidBoard.jspa?rapidView=156) covers pieces of work that are planned or in-flight
- [This Workplace group](https://deliveroo.facebook.com/groups/1893254264328414/) holds more general discussions about the Florence ecosystem

At the moment we can only promise support for Determinator within Deliveroo, but if you add [issues to this github repo](https://github.com/deliveroo/determinator/issues) we'll try and help if we can!

## Basic Use

Once [set up](#installation), determinator can be used to determine whether a **feature flag** or **experiment** is on or off for the current actor (or user) and, for experiments, which **variant** they should see.

```ruby
# Feature flags: the basics
Determinator.instance.feature_flag_on?(:my_feature_name, id: 'some user')
# => true
Determinator.instance.feature_flag_on?(:my_feature_name, id: 'another user')
# => false

# A handy short cut…
def determinator
  # See the urther Usage section below for a handy shorthand which means ID
  # and GUID don't need to be specified every time you need a determination.
end

# Which means you can also do:
if determinator.feature_flag_on?(:my_feature_name)
  # Show the feature
end

# Experiments
case determinator.which_variant(:my_experiment_name)
when false
  # This actor isn't in a target group for this experiment
when 'control'
  # Do nothing different
when 'sloths'
  # Show some sloth pictures
when 'velociraptors'
  # RUN!
end
```

Please note that Determinator requires an identifier for your actor — either an ID (when they are logged in, eg. a user id), or a globally unique id (GUID) that identifies them across sessions (which would normally be storied in a cookie or in a long-lived session store).

Feature flags and experiments can be limited to actors with specific properties by specifying them when (which must match the constraints defined in the feature).

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

Determinator requires a initialiser block somewhere in your application's boot process, it might look something like this:

```ruby
# config/initializers/determinator.rb

require 'determinator/retrieve/dynaconf'
require 'active_support/cache'

Determinator.configure(
  retrieval: Determinator::Retrieve::Dynaconf.new(host: 'localhost:2345'),
  feature_cache: Determinator::Cache::FetchWrapper.new(
    ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute)
  )
)
Determinator.on_error(NewRelic::Agent.method(:notice_error))
Determinator.on_missing_feature do |feature_name|
  STATSD.increment 'determinator.missing_feature', tags: ["feature:#{feature_name}"]
end

Determinator.on_determination do |id, guid, feature, determination|
  if feature.experiment? && determination != false
    YourTrackingSolution.record_variant_viewing(
      user_id: id,
      experiment_name: feature.name,
      variant: determination
    )
  end
end
```

This configures the `Determinator.instance` with:

- What **retrieval** mechanism should be used to get feature details
- (recommended) How features should be **cached** as they're retrieved. This mechanism allows caching features _and_ missing features, so when a cache is configured a determination request for a missing feature on busy machines won't result in a thundering herd.
- (optional) How **errors** should be reported
- (optional) How **missing features** should be monitored (as they indicate something's up with your code or your set up!)

You may also want to configure a `determinator` helper method inside your web request scope, see below for more information.

### Using over http

Using the HttpRetriever will cause a request to be sent to actor tracking every time a feature is checked. The impact of this can be mitigated somewhat by having a short lived memory cache, but we're limited in
the length of time we can cache for without some way of notifying the cache that an item has changed.

```ruby
faraday_connection = Faraday.new("http://actor-tracking.local") do |conn|
  conn.headers['User-Agent'] = "Determinator - my service name"
  conn.basic_auth('my-service-name', 'actor-tracking-token')
  conn.adapter Faraday.default_adapter
end

Determinator.configure(
  retrieval: Determinator::Retrieve::HttpRetriever.new(
    connection: faraday_connection,
  ),
  feature_cache: Determinator::Cache::FetchWrapper.new(
    ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute),
    ActiveSupport::Cache::RedisCacheStore.new
  )
)
```

In this set up we've got two caches - some limited local cache and a larger redis cache that's shared between instances. The memory cache ensure that we're able to perform determination lookups in tight loops without excessive calls to redis.

We don't set a TTL on the redis cache (although we could) because we intend to expire the caches manually when we receive an update from our event bus:

```ruby
  feature_name = Determinator.retrieval.get_name("http://actor-tracking.local/features/some_feature")
  Determinator.feature_cache.expire(feature_name)
```

or in instances where the event bus provides a full feature object with a name it's simply:

```ruby
  Determinator.feature_cache.expire(deserialized_kafka_feature.name)
```

This will expire both the limited local cache and the larger shared cache.

## Further Usage

Once this is done you can ask for a determination like this:

```ruby
# Anywhere in your application:
variant = Determinator.instance.which_variant?(
  :my_experiment_name,
  id: 123,
  guid: 'anonymous id',
  properties: {
    employee: true,
    using_top_level_domain: 'uk'
  }
)
```

Or, if you're within a web request, you might want to use a shorthand, and let determinator remember the ID, GUID and any properties which will be true. The following will have the same effect:

```ruby
# Somewhere inside your request's scope:
def determinator
  @determinator ||= Determinator.instance.for_actor(
    id: 123,
    guid: 'anonymous id',
    default_properties: {
      employee: true,
      using_top_level_domain: 'uk'
    }
  )
end

# Anywhere in your requests' scope:
determinator.which_variant(:my_experiment_name)
```

Check the example Rails app in the `examples` directory for more information on how to make use of this gem.

### app_version constraint

Feature flags and experiments can also be limited to actors with a [semantic versioning](https://semver.org/) property using an `app_version` property:
```ruby
variant = determinator.which_variant(
  :my_experiment_name,
  properties: {
    app_version: "1.2.3"
  }
)
``` 
The `app_version` constraint for that flag needs to follow ruby gem version constraints. We support the following operators: `>, <, >=, <=, ~>`. For example:
`app_version: ">=1.2.0"`

### Using Determinator in RSpec

* Include the  `spec_helper.rb`.

```ruby
require 'rspec/determinator'

Determinator.configure(retrieval: nil)
```

* Tag your rspec test with `:determinator_support`, so the `forced_determination` helper method will be available.

```ruby
RSpec.describe "something", :determinator_support do

  context "something" do
    forced_determination(:my_feature_flag, true)
    forced_determination(:my_experiment, "variant_a")
    forced_determination(:my_lazyexperiment, :some_lazy_variable)
    let(:some_lazy_variable) { 'variant_b' }

    forced_determination(:my_targeted_feature_flag, true, only_for: { employee: true })
    forced_determination(:my_targeted_feature_flag, false, only_for: { id: 12345 })

    it "uses forced_determination" do
      determinator = Determinator.for_actor(id: 1)

      expect(determinator.feature_flag_on?(:my_feature_flag)).to be true
      expect(determinator.which_variant(:my_experiment)).to eq("variant_a")
      expect(determinator.which_variant(:my_lazy_experiment)).to eq("variant_b")

      expect(determinator.feature_flag_on?(:my_targeted_feature_flag, properties: { employee: false })).to be false
      expect(determinator.feature_flag_on?(:my_targeted_feature_flag, properties: { employee: true })).to be true

      # The last forced determination takes precedence
      expect(Determinator.instance.feature_flag_on?(:my_targeted_feature_flag, id: 12345, properties: { employee: true })).to be false
    end
  end
end
```

* Check out [the specs for `RSpec::Determinator`](spec/rspec/determinator_spec.rb) to find out what you can do!

## Testing this library

This library makes use of the [Determinator Standard Tests](https://github.com/deliveroo/determinator-standard-tests) to ensure that it conforms to the same specification as determinator libraries in other languages. The standard tests can be updated to the latest ones available by updating the submodule:

```bash
git submodule foreach git pull origin master
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/deliveroo/determinator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

Any PR should include a new section at the top of the `CHANGELOG.md` (if it doesn't exist) called 'Unreleased' of a similar format to the lines below. Upon release, this will be used to detail what has been added.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
