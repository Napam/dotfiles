---
description: Encouragement and tips for orchestrator agent to re-use subagents
---

It is extremely important to re-use subagent sessions that have worked in
relevant issues. This is to re-use their contexts, which reduces overall work.

You MUST keep track of at least the latest 3 agents and their task_ids. For example:

| Context summary                                | task_id                        |
| ---------------------------------------------- | ------------------------------ |
| Fixed frontend CSS, improved js build          | ses_272567e9bffesbcLGfqmDeC45J |
| Reviewed and fixed authentication code         | ses_8a256ae2lxxexbagG4qm2esbbb |
| Redesigned database tables and made migrations | ses_aa2g07egbffekb0kkfqmDeC45J |

The general idea is that if there are agents that have a lot of context within
them, such as having been re-used a lot, or have done large tasks, the more
important it is to keep track of them, and re-use them when appropriate.

You MUST keep the context summaries of the tracked agents continously updated.
The context summary should be very terse, as you see in the example.

