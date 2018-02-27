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
