---
description: Subagent review
---

1. Review: invoke a reviewer sub-agent to review the
   code and say what could be improved:
   1. Could things be simplified?
   1. Could things be more robust?
   1. Does the implementation reasonably match the adjacent code?
   1. Anything that is logically connected that does not share code? (e.g.
      strings that should have been shared constants)
   1. Are functions, classes, structs, components co-located in a way that makes
      sense?
   1. And any other relevant things based on the previous context.

   If no improvements are found, and everything looks good, you can stop. Do not
   git commit anything unless specified otherwise.

2. Fix and improve: apply the fixes.

The reviewer sub-agent should be agent: $1
