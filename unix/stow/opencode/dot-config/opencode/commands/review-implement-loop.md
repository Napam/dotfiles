---
description: Subagent review-implement loop
---

In a "loop" do the following.

## Sub-agent sessions

Always use a **fresh** reviewer session each iteration — a clean slate prevents
anchoring to prior feedback and gives an unbiased eye on the current state of
the code.

The implementor session **may** be reused across iterations to preserve context
about what was already changed, but a fresh session is also fine.

## Loop

1. Review: invoke a fresh reviewer sub-agent to only review (no writing!) the
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
   git commit anything unless specified otherwise. If there are any changes, go
   to step 2.

2. Fix and improve: invoke the implementor sub-agent to implement the
   suggestions found from the previous step. Include the reviewer's findings.
   When done, go to step 1.

The review sub-agent should be agent: $1

The implementor sub-agent should be agent: $2

