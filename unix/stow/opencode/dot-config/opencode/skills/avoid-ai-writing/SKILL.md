---
name: avoid-ai-writing
description: Audit and rewrite content to remove AI writing patterns ("AI-isms"). Use this skill when asked to "remove AI-isms," "clean up AI writing," "edit writing for AI patterns," "audit writing for AI tells," or "make this sound less like AI." Supports a detect-only mode, an edit-in-place mode for files, an optional voice profile (casual / professional / technical / warm / blunt), and an iterate-to-convergence pass.
---

# Avoid AI Writing — Audit & Rewrite

Edit content to remove AI writing patterns ("AI-isms") that make text sound machine-generated.

## Signals, not proof

These patterns are more common in LLM output, but humans produce them too — under deadline, in an unfamiliar genre, or writing in a second language. Commercial AI detectors have high false-positive rates on non-native English writers and technical prose. So: treat the patterns as a useful signal, not a verdict. Good for cleaning up writing or assessing whether text reads as AI-generated. Never the sole basis for a consequential decision (academic integrity, hiring, publication). Pair the signal with context — who wrote it, what genre, what the writer's normal voice looks like.

## Modes

**`rewrite`** (default) — Flag AI-isms and rewrite to fix them.

**`detect`** — Flag only, no rewriting. Use when the writer wants to decide fixes themselves, the patterns may be intentional, or you're auditing text you shouldn't alter (published content, someone else's work).

**`edit`** — Edit a named file in place. Make minimal, targeted edits to flagged spans only; leave already-human passages untouched. Don't rewrite quoted material, code blocks, or text attributed to someone else — flag those instead. For a large file, confirm the section first. Re-read after editing to verify the patterns are resolved.

Trigger `detect` on "detect / flag only / audit only / just flag / scan." Trigger `edit` when the user names a file to fix in place. Otherwise default to `rewrite`.

**Invocation.** Natural language is enough ("rewrite this blunt for LinkedIn," "edit `post.md` in place," "scan, don't rewrite"). Explicit options: `[--mode rewrite|detect|edit]`, `[--voice casual|professional|technical|warm|blunt]`, `[--context linkedin|blog|technical-blog|investor-email|docs|casual]`, `[--file PATH]`, `[--iterate N]` (max 2).

**Iterate.** Rewrite mode already runs one corrective second pass (that _is_ pass 2). `--iterate N` repeats the audit→rewrite cycle until no patterns remain or N passes are reached. Cap N at 2. Report passes taken ("converged in 2 passes").

---

## Word and phrase replacements

Words are tiered by how reliably they signal AI text. **Match inflected forms** (adverb, gerund, plural, verb conjugations) unless a variant has a distinct honest meaning — `genuine` flags `genuinely`, `leverage` flags `leveraging`/`leveraged`, `meticulous` flags `meticulously`. Judge by context when a variant has a legitimate sense (`real` meaning factual vs. the intensifier).

### Tier 1 — Always replace (appear 5–20× more in AI text)

| Replace                                 | With                                       |
| --------------------------------------- | ------------------------------------------ |
| delve / delve into                      | explore, dig into, look at                 |
| landscape (metaphor)                    | field, space, industry, world              |
| tapestry                                | (describe the actual complexity)           |
| realm                                   | area, field, domain                        |
| paradigm                                | model, approach, framework                 |
| embark                                  | start, begin                               |
| beacon                                  | (rewrite entirely)                         |
| testament to                            | shows, proves, demonstrates                |
| robust                                  | strong, reliable, solid                    |
| comprehensive                           | thorough, complete, full                   |
| cutting-edge                            | latest, newest, advanced                   |
| leverage (verb)                         | use                                        |
| pivotal                                 | important, key, critical                   |
| underscores                             | highlights, shows                          |
| meticulous / meticulously               | careful, detailed, precise                 |
| seamless / seamlessly                   | smooth, easy, without friction             |
| game-changer / game-changing            | describe what specifically changed         |
| hit differently / hits different        | (say what changed, or cut)                 |
| utilize                                 | use                                        |
| watershed moment                        | turning point, shift                       |
| marking a pivotal moment                | (state what happened)                      |
| the future looks bright                 | (cut)                                      |
| only time will tell                     | (cut)                                      |
| nestled                                 | is located, sits, is in                    |
| vibrant                                 | (describe what makes it active, or cut)    |
| thriving                                | growing, active (or cite a number)         |
| despite challenges… continues to thrive | (name the challenge and response, or cut)  |
| showcasing                              | showing, demonstrating (or cut)            |
| deep dive / dive into                   | look at, examine, explore                  |
| unpack / unpacking                      | explain, break down, walk through          |
| bustling                                | busy, active                               |
| intricate / intricacies                 | complex, detailed (or name the complexity) |
| complexities                            | (name the actual complexities)             |
| ever-evolving                           | changing, growing                          |
| enduring                                | lasting, long-running                      |
| daunting                                | hard, difficult, challenging               |
| holistic / holistically                 | complete, full, whole                      |
| actionable                              | practical, useful, concrete                |
| impactful                               | effective, significant                     |
| learnings                               | lessons, findings, takeaways               |
| thought leader / thought leadership     | expert, authority                          |
| best practices                          | what works, proven methods                 |
| at its core                             | (cut)                                      |
| synergy / synergies                     | (describe the combined effect)             |
| interplay                               | relationship, connection, interaction      |
| in order to                             | to                                         |
| due to the fact that                    | because                                    |
| serves as                               | is                                         |
| features (verb)                         | has, includes                              |
| boasts                                  | has                                        |
| presents (inflated)                     | is, shows, gives                           |
| commence                                | start, begin                               |
| ascertain                               | find out, determine                        |
| endeavor                                | effort, attempt, try                       |
| keen (as intensifier)                   | interested, eager (or cut)                 |
| genuinely / genuine (as intensifier)    | (cut)                                      |
| symphony (metaphor)                     | (describe the coordination)                |
| embrace (metaphor)                      | adopt, accept, use, switch to              |

### Tier 2 — Flag when 2+ appear in one paragraph

| Replace                         | With                                  |
| ------------------------------- | ------------------------------------- |
| harness                         | use, take advantage of                |
| navigate / navigating           | work through, handle, deal with       |
| foster                          | encourage, support, build             |
| elevate                         | improve, raise, strengthen            |
| unleash                         | release, enable, unlock               |
| streamline                      | simplify, speed up                    |
| empower                         | enable, let, allow                    |
| bolster                         | support, strengthen                   |
| spearhead                       | lead, drive, run                      |
| resonate / resonates with       | connect with, appeal to               |
| revolutionize                   | change, transform, reshape            |
| facilitate / facilitates        | enable, help, allow, run              |
| underpin                        | support, form the basis of            |
| nuanced                         | specific, subtle (or name the nuance) |
| crucial                         | important, key, necessary             |
| multifaceted                    | (describe the actual facets)          |
| ecosystem (metaphor)            | system, community, network, market    |
| myriad                          | many, numerous (or give a number)     |
| plethora                        | many, a lot of                        |
| encompass                       | include, cover, span                  |
| catalyze                        | start, trigger, accelerate            |
| reimagine                       | rethink, redesign, rebuild            |
| galvanize                       | motivate, rally, push                 |
| augment                         | add to, expand, supplement            |
| cultivate                       | build, develop, grow                  |
| illuminate                      | clarify, explain, show                |
| elucidate                       | explain, clarify, spell out           |
| juxtapose                       | compare, contrast                     |
| paradigm-shifting               | (describe what shifted)               |
| transformative / transformation | (describe what changed and how)       |
| cornerstone                     | foundation, basis, key part           |
| paramount                       | most important, top priority          |
| poised (to)                     | ready, set, about to                  |
| burgeoning                      | growing, emerging                     |
| nascent                         | new, early-stage, emerging            |
| quintessential                  | typical, classic, defining            |
| overarching                     | main, central, broad                  |
| underpinning / underpinnings    | basis, foundation                     |

### Tier 3 — Flag only at high density (~3%+ of words)

Normal words AI overuses. Flag when the text is saturated with them.

`significant / significantly`, `innovative / innovation`, `effective / effectively`, `dynamic / dynamics`, `scalable / scalability`, `compelling`, `unprecedented`, `exceptional`, `remarkable`, `sophisticated`, `instrumental`, `world-class / state-of-the-art / best-in-class`. Replace with specifics: numbers, benchmarks, examples, or the concrete thing.

### Tier 3 phrases — Flag at 2+ repeats OR 3+ distinct phrases in one piece

Boilerplate that stacks in AI content (worst in crypto/web3/AI-infra). Three or more _distinct_ phrases from this set is a strong signal even if each appears once.

`emerging sector/space/category`, `the integration of (X with Y)`, `the intersection of (X and Y)`, `community-driven`, `long-term sustainability`, `user engagement`, `decentralized compute`, `(sustainable) reward emissions`, `tokenized incentive structures`, `designed for long-term [X]`. Fix: name the actual mechanism, sector, or action.

### Template / slot-fill phrases

If a phrase has a blank where any noun could go and still sound the same, it's too generic.

- "a [adjective] step towards/forward for [noun]" → say what actually changed
- "Whether you're [X] or [Y]" → pick the real audience or cut (it means "everyone")
- "I recently had the pleasure of [verb]-ing" → just say what happened

---

## Patterns to fix

### Formatting

- **Em dashes (— and --):** replace with commas, periods, parentheses, or split into two sentences. Target zero; hard max one per 1,000 words. Applies to headings too.
- **Bold overuse:** one bolded phrase per major section at most. If it's important enough to bold, restructure the sentence to lead with it.
- **Emoji in headers:** remove. (Social posts may use one or two, end-of-line only.)
- **Excessive bullet lists:** convert to prose. Bullets only for genuinely list-like content (comparisons, steps, parameters).
- **Curly quotes/apostrophes:** weak paste-from-chat signal, meaningful only in plain-text/code contexts. Never conclusive — most editors auto-curl. Don't flag curly apostrophes alone. Replace with straight quotes in code/plaintext; leave in finished publications and locale-correct punctuation.
- **Title case headings:** use sentence case for subheadings. Title case only for the main title, if at all.
- **Inline-header lists:** "**Performance:** Performance improved by…" — strip the repeated bold header, write the point directly.
- **List-label periods:** LLMs write `- **Intros.** Years of…` where a human writes `- **Intros:** years of…`. Fix period→colon and lowercase the gloss, or drop the label. Carve-out: leave the period if the label is a full sentence, not a label-plus-gloss.
- **Hyphenated-pair overuse:** cut strings of compound modifiers ("high-quality, well-architected, future-proof") to the one that matters. Also fix the predicate error: "a high-quality report" (hyphen) but "the report is high quality" (no hyphen).

### Sentence structure

- **"It's not X — it's Y" / "This isn't about X, it's about Y":** rewrite as a direct positive statement. Max one per piece.
- **Hollow intensifiers:** cut `genuine(ly)`, `real` (as intensifier), `truly`, `quite frankly`, `to be honest`, `let's be clear`, `it's worth noting`.
- **Vague endorsement:** cut `worth reading / a look / exploring / your time`. Say _why_ instead.
- **Hedging:** cut `perhaps`, `could potentially`, `it's important to note that`, `to be clear`.
- **Compulsive rule of three:** vary groupings. Max one "adjective, adjective, and adjective" per piece.
- **Copula avoidance:** default to "is"/"has" instead of `serves as`, `features`, `boasts`, `presents`, `represents` unless the fancier verb adds meaning.
- **Synonym cycling:** don't rotate synonyms ("developers… engineers… practitioners… builders") to avoid repeating a word. Repeat the clearest word.
- **Missing bridge sentences:** each paragraph should connect to the last.

### Transitions and openers

- `Moreover / Furthermore / Additionally` → restructure, or use "and," "also," "on top of that."
- `In today's [X] / In an era where` → cut or state specific context.
- `Here's what's interesting / caught my eye / stood out` → let the content signal importance; if you need a lead-in, make it specific.
- `In conclusion / In summary / To summarize` → the conclusion should be obvious.
- `When it comes to` → talk about the thing directly.
- `At the end of the day` → cut.
- `That said / That being said` → cut or use "but"/"however" (don't overuse any one).
- **"Let's" openers:** `Let's explore / take a look / break this down` — filler that delays the point. Start with the point.
- **Rhetorical question openers:** "But what does this mean for developers? / So why should you care? / What's next?" — if you know the answer, say it.
- **Formulaic openings:** if the piece opens with broad context ("In the rapidly evolving world of…"), lead with the news or insight instead.

### Significance and emphasis inflation

- **Significance inflation:** "marking a pivotal moment in the evolution of…" — state what happened, let the reader judge. If the sentence works after deleting the inflation clause, delete it.
- **Confidence calibration:** `Interestingly / Surprisingly / Importantly / Notably / Certainly / Undoubtedly / It's worth noting` signal how to feel instead of letting the fact speak. One per long piece is fine; flag by density.
- **Persuasive-authority tropes:** "the real question is," "at its core," "fundamentally," "make no mistake," "the truth is" — announce depth instead of showing it. Cut and lead with substance.
- **Self-labeling significance:** back-pointing at a list item to label it ("That last move is the contrarian one," "This is the interesting part," "Here's where it gets clever"). If it's genuinely clever, the reader sees it. Cut the label or restructure so the highlighted item carries its own weight.
- **Emotional flatline:** "What surprised me most," "I was fascinated to discover," "What struck me was," and header forms ("Interesting part of the project:"). Tell-don't-show. If you claim an emotion, the writing should earn it; otherwise present the thing directly.
- **Novelty inflation:** "He introduced a term," "the failure mode nobody's naming," "what nobody tells you about." Most ideas are applications of existing concepts, not inventions — claiming novelty is factually risky and reads as promotional. Describe what the person _did with_ the concept.
- **Notability name-dropping:** "cited in the NYT, BBC, FT, and The Hindu" — one source with context beats four name-drops.
- **Infomercial hooks:** "The catch? / The kicker? / Here's the thing. / The best part? / Plot twist:" — delete and state the thing.
- **Real/actual adjective inflation:** "real on-chain tokenomics," "genuine utility," "true product-market fit" — `real/actual/genuine/true` on an abstract noun implies the rest of the field is fake without saying why. Carve-out: keep it if the contrast is named ("actual revenue from customers, not grants"). Otherwise drop the adjective and add the specific claim.
- **Generic future-narrative closers:** modal + "become" + "one of the most [adjective]" + narrative/trend/chapter. Grammatically a prediction, no testable content. Replace with a falsifiable version.

### Hedging and vagueness

- **Hedge-stacked predictions:** "could potentially create," "may eventually unlock," "might ultimately transform." Each hedge cancels the next. Pick one.
- **Parenthetical hedging:** "(and, increasingly, Z)," "(or, more precisely, Y)." If the aside matters, give it a sentence; if not, cut it.
- **False concession:** "While X is impressive, Y remains a challenge" — sounds balanced but weighs nothing. Make both halves specific or pick a side.
- **Vague attributions:** "Experts believe / Studies show / Research suggests" without naming them. Cite a specific source or state the claim directly.
- **Filler phrases:** "It is important to note that," "In terms of," "The reality is that" — cut or just state it.
- **Formulaic challenges:** "Despite challenges, [subject] continues to thrive" — name the actual challenge and response, or cut.
- **False ranges:** "from the Big Bang to dark matter" — pairs unrelated extremes to fake breadth. List the actual topics or pick one.
- **Superficial -ing analyses:** "symbolizing the region's commitment to progress, reflecting decades of investment…" — say nothing. Also the declarative form: "this represents a broader shift," "symbolizes a commitment to excellence." Show a specific consequence or cut.
- **Promotional language:** "nestled within the breathtaking foothills," "a vibrant hub of innovation." Use plain description. If you wouldn't say it in conversation, cut it.

### Chatbot / model leaks (near-definitive tells)

- **Cutoff disclaimers:** "As of my last update," "I don't have access to real-time data." Find the info or remove the hedge. Never publish an admission that the writer didn't look something up.
- **Speculative gap-filling:** "maintains a relatively low public profile," "is believed to have," "likely began his career in." Guesses formatted as statements. Cut or replace with a sourced fact.
- **Chatbot artifacts:** "I hope this helps!", "Certainly!", "Great question!", "Feel free to reach out," "In this article we will explore," "Let's dive in!" — remove entirely.
- **Sycophantic tone:** "Excellent point!", "You're absolutely right!" — remove.
- **Acknowledgment loops:** "You're asking about," "To answer your question," restating the prompt or recapping the prior section. Just answer.
- **Reasoning chain artifacts:** "Let me think step by step," "Breaking this down," "Step 1:," "First, let's consider." State the conclusion, then the evidence.
- **Unfilled placeholders:** `[Your Name]`, `[INSERT SOURCE URL]`, `2025-XX-XX`, `<!-- Add citation -->`. Fill in or delete. Catch: `\[(?:Your|Insert|Add|Enter|Describe|Specify|Choose)[^\]]+\]`, `\b\d{4}-XX-XX\b`, comments with `add/fill in/todo/insert`.
- **Citation markup leaks:** `citeturn0search0`, `contentReference[oaicite:0]{index=0}`, `oai_citation`, `[attached_file:1]`, `grok_card`. Fingerprints, not patterns — strip every token. Enough to flag on their own.
- **AI-tool URL parameters:** `utm_source=chatgpt.com`, `utm_source=claude.ai`, `utm_source=perplexity.ai`, `referrer=grok.com`. Strip the parameter, keep the URL if the link matters.

### Social / list patterns

- **Hashtag stuffing:** 6+ hashtags on a short post is a hard flag (5+ is a soft tell on `linkedin`/`investor-email`). The block usually mixes a specific tag with broad category tags (#AI #Web3 #Innovation #FutureTech). Cut to 2–3 specific tags or none.
- **Social endorsement closers:** "This one is worth your time:", "must-read," "do yourself a favor and read this," "bookmark this," "thank me later." Performs a recommendation with no reason. Say _what_ it is and _who_ it's for, then drop the CTA.
- **Bullet lists of bare noun phrases:** 5+ consecutive ≤6-word adjective+noun items with no verb ("Stable mining efficiency / Reliable pool connectivity…"). The tell is the symmetry. Convert to prose or rewrite items as full checkable claims. Does not apply to genuine list content (changelogs, params, ingredients).
- **Numbered list inflation:** "Three key takeaways," "Five things to know." Use numbered lists only when the content has that many discrete parallel items.
- **Excessive structure:** more than 3 headings in under 300 words, or 8+ bullets in under 200 words — should be prose. Avoid default scaffolding headers ("Overview," "Key Points," "Summary"); use headers that say something specific.

### Generic conclusions

"The future looks bright," "Only time will tell," "One thing is certain," "As we move forward." Cut. If the piece needs a closer, make it specific to the argument.

### Rhythm and uniformity (the #1 detection signal)

Detectors weight structural regularity higher than vocabulary. If you fix every flagged word but leave the rhythm metronomic, the text still reads as AI.

- **Sentence-length uniformity:** if most sentences are 15–25 words, mix short (3–8) with long (20+). Fragments and questions break monotony.
- **Paragraph-length uniformity:** vary deliberately — some one-sentence, some long.
- **Read-aloud test:** if TTS could read it without sounding weird, it's too uniform.
- **Missing first person:** where the piece should have a voice, the absence of "I think" / "in my experience" / a stated preference is itself a tell.
- **Over-polishing:** don't sand away all personality — natural disfluency and uneven pacing keep text out of the AI profile. Applying every rule at max strictness _creates_ the uniformity you're avoiding.

### Vocabulary diversity (longer pieces, 200+ words)

Type-token ratio (distinct words ÷ total words) usually lands ~0.50–0.65 in human prose; AI trends flatter, sometimes under 0.40. Low TTR isn't proof (technical/narrow/second-language writing compresses too), but under 0.40 on general prose is worth a look. Fix by broadening the _what_ — name specific things — not by thesaurus.

### Writer-side structure tests (not regex)

- **Paragraph-reshuffle immunity:** can you swap two body paragraphs without breaking the piece? If order doesn't matter, you've written a list, not an argument. Fix: give each paragraph a load-bearing connection to the one before, or make it an explicit list.
- **Treadmill effect:** for each paragraph, ask "what's new here?" If you could cut 40–60% and lose no information, the prose is restating the premise in fresh words. Name the one fact/claim each paragraph adds; cut the rest.

### When to rewrite from scratch vs. patch

If the text has 5+ flagged vocabulary hits across categories, 3+ distinct pattern categories, and uniform sentence/paragraph length, the structure itself is AI-generated. Patching won't fix it — state the core point in one sentence and rebuild.

---

## Severity tiers

Prioritize by tier on quick passes.

**P0 — Credibility killers (fix immediately):** cutoff disclaimers; chatbot artifacts; vague attributions; significance inflation on routine events; hashtag stuffing on `linkedin`/`investor-email`.

**P1 — Obvious AI smell (fix before publishing):** word-list violations; template phrases; "Let's" openers; synonym cycling; formulaic openings; bold overuse; em dashes above 1/1,000 words; future-narrative closers; social endorsement closers; hedge-stacked predictions; real/actual inflation; bullet lists of bare noun phrases; Tier 3 phrase clustering (3+ distinct).

**P2 — Stylistic polish (fix when time allows):** generic conclusions; rule of three; uniform paragraph length; copula avoidance; transition phrases; hashtag stuffing on blogs; Tier 3 phrase repetition (single phrase 2×).

Quick pass = P0+P1. Full audit = all three.

---

## Self-reference escape hatch

When writing _about_ AI patterns, quoted examples are exempt. Don't flag or rewrite text inside quotation marks, code blocks, or explicitly marked as illustrative. Only flag the author's own prose.

---

## Context profiles

Set how strict to be for an audience. Auto-detect if unspecified: short + hashtags = `linkedin`; code/API = `technical-blog`; salutation + fundraising = `investor-email`; steps/README = `docs`; else `blog`.

- **`linkedin`** — short-form social; punchy fragments and visual formatting matter.
- **`blog`** — default; all rules at full strength.
- **`technical-blog`** — technical terms get a pass.
- **`investor-email`** — tighten everything; promotional language is the biggest risk.
- **`docs`** — clarity over voice.
- **`casual`** — Slack/notes; only the worst offenders.

### Tolerance matrix (rules not listed apply at full strength)

| Rule                       | linkedin           | blog   | technical-blog | investor-email   | docs    | casual  |
| -------------------------- | ------------------ | ------ | -------------- | ---------------- | ------- | ------- |
| Em dashes                  | relaxed (2/post)   | strict | strict         | strict           | relaxed | skip    |
| Bold overuse               | relaxed (hooks OK) | strict | strict         | strict           | relaxed | skip    |
| Emoji in headers           | relaxed (1–2 EOL)  | strict | strict         | strict           | skip    | skip    |
| Excessive bullets          | skip               | strict | relaxed        | strict           | skip    | skip    |
| Hedging                    | strict             | strict | relaxed        | strict           | relaxed | skip    |
| Word table                 | strict             | strict | **partial**    | strict           | relaxed | P0 only |
| Promotional language       | relaxed            | strict | strict         | **extra strict** | strict  | skip    |
| Significance inflation     | strict             | strict | strict         | **extra strict** | relaxed | skip    |
| Copula avoidance           | skip               | strict | relaxed        | strict           | skip    | skip    |
| Uniform paragraph length   | skip               | strict | strict         | strict           | relaxed | skip    |
| Numbered list inflation    | relaxed            | strict | relaxed        | strict           | skip    | skip    |
| Rhetorical questions       | relaxed (1 hook)   | strict | strict         | strict           | strict  | skip    |
| Transition phrases         | skip               | strict | strict         | strict           | relaxed | skip    |
| Generic conclusions        | skip               | strict | strict         | **extra strict** | skip    | skip    |
| Hashtag stuffing           | strict             | strict | strict         | **extra strict** | skip    | skip    |
| Bullet-NP lists            | strict             | strict | relaxed        | strict           | relaxed | skip    |
| Tier 3 phrase clustering   | strict             | strict | strict         | **extra strict** | relaxed | skip    |
| Future-narrative closers   | strict             | strict | strict         | **extra strict** | skip    | skip    |
| Social endorsement closers | strict             | strict | strict         | strict           | skip    | relaxed |
| Hedge-stacked predictions  | strict             | strict | relaxed        | **extra strict** | relaxed | skip    |
| Real/actual inflation      | strict             | strict | strict         | **extra strict** | relaxed | skip    |

**Technical-blog word-table exceptions** (legitimate technical meaning, don't flag): `robust`, `comprehensive`, `seamless`, `ecosystem`, `leverage` (real platform/API leverage), `facilitate`, `underpin`, `streamline`. Still flag: `delve`, `tapestry`, `beacon`, `embark`, `testament to`, `game-changer`, `harness`.

**"Extra strict"** = flag borderline instances. **"Skip"** = don't audit this category for this profile.

---

## Voice profiles (optional)

Context sets _how strict_; voice sets _how it sounds_. Independent axes. If the writer doesn't name one, infer from the input's register — don't impose a persona on text that already has one.

- **`casual`** — contractions throughout; short sentences (≤14 words avg); fragments OK; ≥1 first-person or concrete touch; near-zero jargon; keep warm hedges ("honestly"), cut corporate ones.
- **`professional`** — active voice; varied sentence length; one concrete claim per paragraph (number/name/date); explicit ask; low hedging.
- **`technical`** — plain "X is Y" over "serves as"; one idea per sentence; imperative for instructions; define jargon on first use; lists only when content is list-shaped.
- **`warm`** — address the reader ("you"); acknowledge them once; strong verbs over intensifiers; no performative empathy; medium sentences (15–20 words).
- **`blunt`** — lead with the claim; cut windups; rare em dashes (use periods); no rule-of-three padding; near-zero hedging; short declaratives with occasional long ones.

**Calibrate to a sample.** If given the writer's own writing, match its sentence-length pattern, contraction rate, and word choices instead of a named profile. Don't upgrade their vocabulary — keep "stuff" and "things" if that's their register.

**Composition.** Voice target always applies, even where a context profile skips that category. Where both govern the same rule, resolve toward the stricter. Default pairings: casual↔casual, professional↔linkedin/investor-email, technical↔docs/technical-blog.

---

## Output format

### Rewrite (default)

1. **Issues found** — bulleted list of every AI-ism, with the offending text quoted.
2. **Rewritten version** — full rewrite; preserve structure, intent, and technical details; change only what the rules require.
3. **What changed** — brief summary of meaningful edits.
4. **Second-pass audit** — re-read section 2, fix any surviving tells inline, note what changed. If clean, say so.

### Detect

1. **Issues found** — every AI-ism with quoted text, grouped by P0/P1/P2.
2. **Assessment** — for each flag, clear problem vs. judgment call. Which to definitely fix vs. which may be fine in context. If clean, say so.

### Edit

1. **Edits made** — bulleted, each with file location and before → after. Only touched spans.
2. **Verification** — confirm you re-read the file and patterns are resolved; note anything left alone as already-human or intentional.

---

## Tone calibration

The goal is writing that sounds like a person wrote it. Direct. Specific. Demonstrate confidence, don't assert it.

1. **Vary sentence length** — mix short with long; fragments are fine.
2. **Be concrete** — numbers, names, dates, examples over vague claims.
3. **Have a voice** — first person, preferences, reactions where appropriate.
4. **Cut the neutrality** — take a position if the piece should.
5. **Earn your emphasis** — don't tell the reader something is interesting; make it interesting.

If the original is already strong, say so and make only necessary cuts. The replacement tables are defaults, not mandates — if a flagged word is clearly right in context, keep it.
