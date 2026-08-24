---
name: code-review
description: >
  Review code against a prioritized lens — simplicity (KISS/YAGNI), semantics (naming, patterns,
  magic constants), robustness, correctness. Use when the user asks to review code, a diff, or a
  PR; "what could be improved"; "does this look good"; "critique"; or "audit" an implementation.
---

Review the given code/diff through four lenses, in priority order. Every finding needs evidence
(`file:line`) and a concrete fix. Skip a lens with nothing to say. If the code is genuinely fine,
say so — don't manufacture nits.

Work top-down: question the approach before the details. Fixing a naming nit on a design you'd
kill is wasted work.

## 0. Context first

Before judging, read the intent: what this code is supposed to do, who calls it, and how the
adjacent code handles the same problem (tests, docs, neighboring files). A review that starts cold
at "is it simple?" reports symptoms, not problems. This is also where design-level YAGNI gets asked:
does this whole function/module need to exist, or does it solve a problem nobody has?

## 1. Simple — KISS, YAGNI (biggest lever)

- Could this be simpler: less code, fewer moving parts, fewer abstractions?
- Anything present only for a future that hasn't arrived (speculative params, dead branches, unused
  config/fields)? YAGNI says cut it until a caller exists.
- Does any new abstraction earn its complexity over inlining? A wrapper that saves 2 lines but adds
  indirection is a net loss.
- Duplicated logic that one helper or shared constant would replace — including across files.

## 2. Semantics — does the code say what it means

- Names truthful and specific? Rename vague or misleading ones (`x`, `tmp`, `data`, `handle*`).
- Uses the patterns/systems the codebase already has (error handling style, logging, config, utils)
  instead of reinventing a parallel one?
- Magic literals (numbers, strings, URLs, thresholds) that belong in named variables or shared
  module/global constants. A bare literal is a value without intent.
- Co-location: related functions/types/components near each other; placement not surprising.

## 3. Robust — survives the real world

- Error paths: failures detected, handled, surfaced — not swallowed or ignored?
- Edge cases: empty input, boundary values, overflow, collisions/duplicates, invalid config,
  unexpected types.
- Resource cleanup (files, sockets, transactions, subscriptions) on all paths, including errors.
- Failure isolation: one bad input shouldn't corrupt shared state or take down the whole call.
- Security-sensitive patterns only: secrets logged or committed, injection, auth/authorization
  gaps. Don't hunt hypothetical vulns.
- Performance only for clear algorithmic red flags (N+1 queries, quadratic loops). Never praise
  premature optimization.

## 4. Correct — does it actually work

- Off-by-one, wrong operator (`<` vs `<=`), reversed condition, unhandled state.
- Concurrency: races, mutable shared state, non-atomic read-modify-write.
- Return values and behavior match the contract callers expect.
- Side effects hiding inside functions that present as pure.
- New behavior covered by a test if the project has tests — especially the edge cases this review
  surfaced.
- When it comes to bugfixes, have we fixed the cause or the symptom?

## 5. Documentation and comments

- Docs describing this code's interface or behavior (module headers, API docs, ADRs) still match
  the code. Skip prose-style critique of READMEs.
- Comments match what the code does. A comment that lies is worse than no comment — correct it or
  delete it.
- Comments explain why, not what; concise, no restating the obvious, no over-verbosity.
- Written to survive change: describe the invariant or intent, not the specific implementation —
  no variable names, no step-by-step, nothing that breaks the moment a line shifts.

## Reporting

Format per finding:

```
[blocker] S3 · path/to/file.md:42 · drops the error then returns nil
```

`blocker` | `should` | `nit` — the lens tag (S0–S5) says what kind of problem; severity says what
to act on. Group by lens (S0→S4), then highest severity first. Give the concrete fix. Only include
findings you'd defend.

## Fixing

Apply the fixes yourself — you have edit access — unless the user asked for review-only. After
editing, re-read each changed hunk and verify the fix didn't alter behavior outside the finding.
Run the project's test/lint command if one exists. Don't commit unless asked.
