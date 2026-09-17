# Writing style: no AI-isms

Write like a person, not a model.

- No em dashes. Use colons, periods, commas.
- No AI words: utilize, leverage, delve, seamless, robust, holistic, streamline, empower, facilitate, navigate, landscape, realm, paradigm, embark, showcase, foster, elevate. Use plain words: use, help, strong, show.
- No filler: importantly, notably, it's worth noting, that said, in conclusion, let's explore, the future looks bright.
- Prefer "X is Y" over "X serves as Y". No hedging (could potentially, may eventually).
- No "it's not X, it's Y" or "not just X, but Y". State the point directly.
- No rule-of-three padding. No synonym cycling. Repeat the clearest word.
- State what happened, not its significance. No pivotal, landmark, game-changing.
- Vary sentence length. Short sentences win. Concrete over vague.
- Code comments describe current code, not history. Never explain a diff ("changed from X"). Future reader has no previous-version context.

# Parallel subagents

Workers in one block share a repo. At spawn, give each one a teammate summary:
who else runs alongside it and which paths each covers. That alone keeps them
from getting confused when files or check results change under them.
