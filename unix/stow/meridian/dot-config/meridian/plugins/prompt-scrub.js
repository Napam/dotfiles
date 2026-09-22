// WARN: no imports. Meridian hot-reloads this entry file with a ?t=
// cache-buster, but imported helpers stay ESM-cached and would go stale.

// WARN: Layer A inside opencode runs the third-party scrub (capital "OpenCode"
// to "the assistant") before meridian sees the request, so targeted rules take
// every brand spelling plus "the assistant". Prefix anchors swallow the line
// tail (drops "trained by Meta MSL"). Keep these ahead of OPENCODE_BRAND_TOKEN
// inside scrub().
// WARN: each anchor must cover every spelling the brand token can rewrite a
// variant to. If pass 1 misses and brand emits "the assistant", pass 2 matches
// the "the assistant" arm and scrub stops being idempotent.
// Deliberately narrow: a same-shaped line from another source loses its tail.
const V2_CAP_IDENTITY_LINE =
  /You are (?:OpenCode|Opencode|OPENCODE|the assistant)[A-Za-z0-9]*, a coding agent[^\n]*\n?/g;
// "You are opencode," is identity-shaped; filenames, URLs, and commands cannot
// start with it. No Layer-A alternation: Layer A never mangles lowercase.
const V2_LOWER_IDENTITY_LINE = /You are opencode,[^\n]*\n?/g;
const V2_HARNESS_CLAUSE =
  /\brunning in (?:OpenCode|Opencode|OPENCODE|the assistant)[A-Za-z0-9]*, a coding agent harness/g;
const V2_TOOL_USE_HEADER =
  /# Tool Use - (?:OpenCode|Opencode|OPENCODE|the assistant)[A-Za-z0-9]* Specifics/g;
// Standalone: POWERED_BY_LINE's "the model named" phrasing is dead on v2, so
// a reworded identity prefix leaves the Meta MSL clause with no fallback.
// [^\n] not [.] so dotted model names (gemini-2.5-pro) still match; the
// (trained|built) by Meta( MSL)? tail survives clause reword and connectors
// other than a comma.
// WARN: trailing [ \t]* not \s*: \s* eats the following newline, joins this
// line to the next, and OPENCODE_ENV_BLOCK then swallows the preceding line
// (preamble case) or loses its (?:^|\n) anchor before a bare <env> (leak).
const V2_POWERED_BY_CLAUSE =
  /You are powered by [^\n]*?(?:trained|built) by Meta(?: MSL)?\.[ \t]*/g;

const OPENCODE_IDENTITY_LINE = /You are OpenCode, the best coding agent on the planet\.[^\n]*\n+/;
const OPENCODE_FEEDBACK_BLOCK =
  /If the user asks for help or wants to give feedback[\s\S]*?github\.com\/anomalyco\/opencode[^\n]*\n+/;
const OPENCODE_DOCS_PARAGRAPH =
  /When the user directly asks about OpenCode[\s\S]*?opencode\.ai\/docs[^\n]*\n+/;
const OPENCODE_OBJECTIVITY_BRAND = /It is best for the user if OpenCode honestly applies/;
const OMO_IDENTITY_LINE = /You are "Sisyphus"[^\n]*from OhMyOpenCode\.[^\n]*\n+/;
const OMO_ENV_BLOCK = /<omo-env>[\s\S]*?<\/omo-env>\n*/;
const POWERED_BY_LINE = /You are powered by the model named [^\n]+\n/;
// WARN: the duplicate env preamble trips Anthropic's third-party-impersonation
// gate. Bisected 2026-04-21: removing this block (or just the preamble line)
// makes opus succeed; sonnet/haiku unaffected.
// Matches any preamble line containing "environment you are running" (both
// the "Here is some useful information..." and "The environment you are
// running in is now:" renderers exist); /g clears duplicates in one pass so
// scrub() stays idempotent. No trailing newline in the match: adjacent blocks
// would otherwise eat the newline the next preamble needs. (?:^|\n) up front
// also catches a block at the start of the input.
const OPENCODE_ENV_BLOCK =
  /(?:^|\n)(?:[^\n]*environment you are running[^\n]*\n)?<env>[\s\S]*?<\/env>/g;
// WARN: case-sensitive on purpose. A lowercase-blind replace corrupts
// opencode.json, opencode mcp, and https://opencode.ai references that
// legitimately appear in system prompts. Trailing \b on the standalone forms
// keeps identifiers intact: \bOPENCODE\b cannot match inside OPENCODE_HOME
// (underscore is a word character), same reasoning as opencode.json.
// The compound alternative eats the whole token: OpenCodeSDK/OpencodeSDK/
// OPENCODESDK become "the assistant", never "the assistantSDK". Its [A-Z]
// lookahead is what keeps OPENCODE_HOME intact (underscore matches neither
// the \b arm nor [A-Z]).
const OPENCODE_BRAND_TOKEN =
  /\b(?:OpenCode|Opencode|OPENCODE)(?:\b|(?=[A-Z])[A-Za-z0-9]*)/g;

const GENERIC_IDENTITY =
  "You are an expert coding assistant. You help users with software engineering tasks by " +
  "reading files, executing commands, editing code, and writing new files.\n";
const GENERIC_OBJECTIVITY = "It is best for the user if the assistant honestly applies";

export function scrub(system) {
  if (!system) return system;
  return system
    .replace(V2_CAP_IDENTITY_LINE, GENERIC_IDENTITY)
    .replace(V2_LOWER_IDENTITY_LINE, GENERIC_IDENTITY)
    .replace(V2_HARNESS_CLAUSE, "running in a coding agent harness")
    .replace(V2_TOOL_USE_HEADER, "# Tool Use")
    .replace(V2_POWERED_BY_CLAUSE, "")
    .replace(OPENCODE_IDENTITY_LINE, GENERIC_IDENTITY)
    .replace(OPENCODE_FEEDBACK_BLOCK, "")
    .replace(OPENCODE_DOCS_PARAGRAPH, "")
    .replace(OPENCODE_OBJECTIVITY_BRAND, GENERIC_OBJECTIVITY)
    .replace(OMO_IDENTITY_LINE, "")
    .replace(OMO_ENV_BLOCK, "")
    .replace(POWERED_BY_LINE, "")
    .replace(OPENCODE_ENV_BLOCK, "")
    .replace(OPENCODE_BRAND_TOKEN, "the assistant")
    .replace(/\n{3,}/g, "\n\n")
    .replace(/\s+$/, "");
}

const plugin = {
  name: "prompt-scrub",
  version: "1.0.0",
  description: "Scrubs identity lines and env blocks from the system context.",
  adapters: ["opencode"],
  // WARN: returning undefined poisons the pipeline accumulator and 500s the
  // request; always return a ctx object.
  onRequest(ctx) {
    if (!ctx.systemContext) return ctx;
    const scrubbed = scrub(ctx.systemContext);
    if (scrubbed === ctx.systemContext) return ctx;
    return { ...ctx, systemContext: scrubbed };
  },
};

export default plugin;
