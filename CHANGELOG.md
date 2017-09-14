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
