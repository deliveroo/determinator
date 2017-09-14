# HEAD

Breaking changes:
- When asking for a determination, you must specify the `properties` of the given actor, not the `constraints` (as `constraints` makes less sense) (#27)

Features:
- Remove siphon drain step, determinator now requires just a drain that expires caches. Also Removes the caching step for ID lookup (#24)
- Added Determinator RSpec helper (#26)
- Allows Determinator to accept both legacy and new style contraint and override specifications, for upcoming Florence API migration (#25)
