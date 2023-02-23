# 2.9.3

Feature:
- Add optional `feature` argument to `feature_flag_on?` and `which_variant` methods of ActorControl, to reuse an existing feature.
- Add mutex to synchronise access to caches in Cache::FetchWrapper.

# 2.9.2

Bug fix:
- Fix parsing fixed determinations when the variant is an empty string

# 2.9.1

Feature:
- Add `callback` argument to Control, allowing custom logic to notice the determination.

# 2.9.0

Feature:
- When an app_version does not comply with semantic versioning specifications (e.g.: 2021.11.05 with a trailing zero instead of the correct 2021.11.5), return false.

# 2.8.0

Feature:
- When a GUID bucketed feature is misconfigured, handle the error and return false.

# 2.7.1

Feature:
- Add `before_retrieve` and `after_retrieve` hooks for `Determinator::Retrieve::HttpRetriever`

# 2.7.0

⚠️ This release includes breaking changes ⚠️

Interface change:
- Constraints which are not arrays of strings are no longer accepted; if present, the library returns false and logs an error.

# 2.6.0

Interface change:
- A `feature_cache` is now required to use Determinator. See the `examples/determinator-rails/config/initializers/determinator.rb` for a quick start.

# 2.5.4

Bug fix:
- Apply app_version logic to structured request.app_version too

# 2.5.3

Bug fix:
- Avoid errors when updating the gem and using persistent cache resulting in null fixed_determinations

# 2.5.2

Feature:
- Add structured_bucket to Feature
- Add `#retrieve` method to the Control
- Add optional `feature` argument to `feature_flag_on?` and `which_variant`, to reuse an existing feature

# 2.5.1

Feature:
- Add explain functionality for determinations

# 2.5.0

Feature:
- Add fixed determinations

# 2.4.4

Bug fix:
- Count repeated determinations instead of tracking separately

# 2.4.3

Feature:
- Add Sinatra endpoint tracking

Bug fix:
- Remove endpoint tracking of PATH_INFO

# 2.4.2

Feature:
- Add endpoint information to tracking request

Bug fix:
- Make tracking request "start" attribute an actual time

# 2.4.1

Bug fix:
- Update "fake" retrievers to match behaviour introduced in `v2.3.1` when a feature is missing

# 2.4.0

Feature:
- Add tracker middleware

# v2.3.1 (2019-05-25)

Feature:
- Add a flag `cache_missing[true]` to the cache wrapper to control the cache behaviour on 404

Bug fix:
- Ensure errors are not cached by the cache wrapper

# v2.3.0 (2019-09-06)

Feature:
- `RSpec::Determinator` can apply `app_version` constraints but no longer supports multiple `forced_determination` calls on the same feature. [See the PR for an in-depth write-up.](https://github.com/deliveroo/determinator/pull/63)

# v2.2.1 (2019-07-29)

Bug fix:
- Ensures the dependency to semantic is included at runtime

# v2.2.0 (2019-07-25)

Feature:
- Adds support for `app_version` constraints (#60)

# v2.1.0 (2019-05-01)

Feature:
- Adds HttpRetriever and cascading cache support (#58)

# v2.0.0 (2019-02-19)

Breaking change:
- Removes routemaster-drain support, the gem is also no longer a dependency. (#55)

Feature:
- Adds retriever for Dynaconf. (#55)

# v1.2.0 (2018-06-12)

Feature:
- Adds to how `single` bucketed features operate. Now rollouts imply random determination, though 0% rollouts and 100% rollouts remain representing no-one and everyone respectively, ensuring that this change is backward compatible. (#52)

# v1.1.2 (2018-03-07)

Bug fix:
- Ensures that `Determiantor::Retrievve::File` tolerates feature names that quack `#to_s`. (#50)

# v1.1.1 (2018-02-27)

Bug fix:
- Ensures the `configure` method calls the correct method when a legacy error proc is given as a parameter. (#49)

# v1.1.0 (2018-02-07)

⚠️ This release includes breaking changes to `RSpec::Determinator` ⚠️

Breaking change:
- If two `forced_determination`s are made within one rspec test case, it is now the _last_ one that takes precedence (not the first). (#47)

Bug fix:
- `forced_determination`s which are called with differently typed parameters (eg. integer vs. string, boolean vs. string) will now work in the same way that real determination will. (#47)

# v1.0.0 (2018-02-05)

⚠️ This release includes breaking changes ⚠️

Breaking change:
- Changes retrieval caching so that 404s are cached as well as positive feature retrievals. This means that an unconfigured feature won't result in a thundering herd of requests to Florence. (#46)

Feature:
- Changes tests to use the [Determinator standard tests](https://github.com/deliveroo/determinator-standard-tests) (#41)
- Supports the use of the 'single' bucket type for features, which allows (only) feature flags to be on or off, without any `id` or `guid` specified. (#41)
- Adds Determintion callbacks: trigger a block when a determination is made, allowing for experiment tracking. (#45)

# v0.12.1 (2018-02-01)

Bug Fix:
- Allow `.for_actor` calls when using `RSpec::Determinator` to test code that uses determinator. (#44)

# v0.12.0 (2018-01-23)

Feature:
- Adds the `Determinator.feature_details` method, which allows lookup of feature details as are currently available to Determinator. Whatever is returned here is what Determinator is acting upon. (#38)

Bug Fix:
- Upgrades a dependency of the example rails app which has a known vulnerability. (#39)

# v0.11.1 (2017-10-27)

Feature:
- Allows the use of example-scoped variables for outcomes and constraints in `RSpec::Determinator`'s mocks. (#36)

# v0.11.0 (2017-10-13)

Bug fix:
- Ensure constraints and properties are string-keyed so that they match regardless of which are used (#33)
- Be more permissive with the situations where `Rspec::Determinator` can be used (#34)
- Swallow not found errors from routemaster so determinator isn't too shouty, allow them to be tracked. (#35)

# v0.10.0 (2017-09-15)

Feature:
- Determinator can now be configured to log errors with any external service (#32)

# v0.9.1 (2017-09-14)

Bug fix:
- Fixes an issue where PR #27 missed one instance of syntactic sugar where `constraints` needed to be switched to `properties`. (#30)

# v0.9.0 (2017-09-14)

This version of Determiantor introduces some breaking changes as we move to getting the Florence ecosystem more ready for a wider audience. A 1.0.0 release will follow shortly with few additional features, but with significantly more documentation.

Breaking changes:
- When asking for a determination, you must specify the `properties` of the given actor, not the `constraints` (as `constraints` makes less sense) (#27)
- Remove siphon drain step, determinator now requires just a drain that expires caches. Also Removes the caching step for ID lookup (#24)

Features:
- Added Determinator RSpec helper (#26)
- Allows Determinator to accept both legacy and new style contraint and override specifications, for upcoming Florence API migration (#25)
