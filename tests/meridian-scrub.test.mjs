import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import plugin, {
  scrub,
} from "../unix/stow/meridian/dot-config/meridian/plugins/prompt-scrub.js";

// Verbatim v2.0.12 identity strings from recon.
const CAPITAL_IDENTITY =
  "You are OpenCode, a coding agent that helps users with software engineering tasks. " +
  "You are powered by {{MODEL_NAME}}, a large language model trained by Meta MSL.";
const LOWERCASE_IDENTITY =
  "You are opencode, an interactive CLI tool that helps users with software engineering tasks. " +
  "Use the instructions below and the tools available to you to assist the user.";
const HARNESS_IDENTITY =
  "You are an AI agent running in OpenCode, a coding agent harness. " +
  "Help the user accomplish their goals using the tools you have available.";
const TOOL_USE_HEADER = "# Tool Use - OpenCode Specifics";
const V1_IDENTITY = "You are OpenCode, the best coding agent on the planet.";
const REWORDED_IDENTITY =
  "You are OpenCode, an AI pair programmer. " +
  "You are powered by claude-opus-4-6, a large language model trained by Meta MSL.";
const CASE_DRIFT_IDENTITY =
  "You are Opencode, a coding agent that helps users with software engineering tasks. " +
  "Be concise.";
const LOWER_REWORDED = "You are opencode, the best terminal companion. Follow these rules.";
const CASE_VARIANTS =
  "Opencode ships fast. OpenCodeSDK integrates. " +
  "Standalone OPENCODE here. OpencodeSDK rocks. OPENCODESDK too. Keep OPENCODE_HOME set.";

const ENV_BLOCK = [
  "Here is some useful information about the environment you are running in:",
  "<env>",
  "  Current conversation session ID: ses_abc123",
  "  Working directory: /Users/naphat/.config/dotfiles",
  "  Workspace root folder: /Users/naphat/.config/dotfiles",
  "  Is directory a git repo: yes",
  "  Platform: darwin",
  "  Prefer /tmp over generic system temporary directories.",
  "</env>",
].join("\n");

// Second renderer spelling from the v2 binary ("changed" variant).
const ENV_BLOCK_CHANGED = [
  "The environment you are running in is now:",
  "<env>",
  "  Current conversation session ID: ses_def456",
  "  Platform: darwin",
  "</env>",
].join("\n");

const PRESERVE = [
  "opencode.json",
  "opencode.jsonc",
  "opencode mcp add",
  "https://opencode.ai/v2/docs",
  "~/.config/opencode/themes/",
];

test("plugin shape", () => {
  assert.equal(plugin.name, "prompt-scrub");
  assert.deepEqual(plugin.adapters, ["opencode"]);
  assert.equal(typeof plugin.onRequest, "function");
  assert.equal(typeof scrub, "function");
});

test("plugins.json registers only our scrub", () => {
  const configURL = new URL(
    "../unix/stow/meridian/dot-config/meridian/plugins.json",
    import.meta.url,
  );
  const config = JSON.parse(readFileSync(configURL, "utf8"));
  const paths = config.plugins.map((p) => p.path);
  assert.equal(paths.length, 1, JSON.stringify(paths));
  // WARN: relative paths resolve against ~/.config/meridian/plugins/ and are
  // matched against a readdir list filtered to .ts/.js. Any other extension
  // (e.g. .mjs) is silently dropped and the scrub never loads.
  assert.equal(paths[0], "prompt-scrub.js");
  assert.equal(config.plugins[0].enabled, true);
  assert.ok(!paths.some((p) => p.includes("@rynfar")), JSON.stringify(paths));
  // No hardcoded home directory; the manifest must stay portable across users.
  assert.ok(!paths.some((p) => p.startsWith("/")), JSON.stringify(paths));

  const pluginURL = new URL("plugins/prompt-scrub.js", configURL);
  assert.ok(existsSync(pluginURL), `plugin missing next to manifest: ${pluginURL}`);

  // WARN: Node resolves the symlinked plugin to its realpath, so the type:module
  // marker must sit in the plugin dir itself. Without it the ESM export syntax
  // fails to import and the plugin errors out.
  const pkg = JSON.parse(readFileSync(new URL("plugins/package.json", configURL), "utf8"));
  assert.equal(pkg.type, "module");
});

test("v2 identity strings lose brand and residue", () => {
  const cases = [
    [CAPITAL_IDENTITY, ["Meta MSL"]],
    [LOWERCASE_IDENTITY, ["interactive CLI tool"]],
    [HARNESS_IDENTITY, ["running in the assistant,"]],
    [TOOL_USE_HEADER, ["Specifics"]],
  ];
  for (const [input, residues] of cases) {
    const out = scrub(input);
    assert.ok(!out.includes("OpenCode"), `brand left in: ${out}`);
    for (const residue of residues) {
      assert.ok(!out.includes(residue), `residue ${residue} left in: ${out}`);
    }
  }
});

test("reworded identity loses the powered-by clause", () => {
  const out = scrub(REWORDED_IDENTITY);
  assert.ok(!out.includes("Meta MSL"), out);
  assert.ok(!out.includes("powered by"), out);
  assert.ok(!out.includes("OpenCode"), out);
});

test("generalized lowercase anchor", () => {
  const out = scrub(LOWER_REWORDED);
  assert.ok(!out.includes("opencode,"), out);
  assert.ok(out.includes("You are an expert coding assistant."), out);
});

test("case variants scrubbed, identifiers preserved", () => {
  const out = scrub(CASE_VARIANTS);
  assert.ok(!out.includes("Opencode"), out);
  assert.ok(!out.includes("OpenCodeSDK"), out);
  assert.ok(!out.includes("Standalone OPENCODE"), out);
  assert.ok(!out.includes("OpencodeSDK"), out);
  assert.ok(!out.includes("OPENCODESDK"), out);
  assert.ok(out.includes("OPENCODE_HOME"), out);
});

test("idempotent on case-drifted identity lines", () => {
  const drifts = [
    "You are Opencode, a coding agent that helps users with software " +
      "engineering tasks. Be concise.",
    "You are OPENCODE, a coding agent that reviews pull requests. Be concise.",
    "You are OpenCodeX, a coding agent that reviews pull requests. Be concise.",
    "You are an AI agent running in Opencode, a coding agent harness. Help now.",
    "# Tool Use - Opencode Specifics",
  ];
  for (const input of drifts) {
    const once = scrub(input);
    assert.equal(scrub(once), once, input);
    for (const spelling of ["OpenCode", "Opencode", "OPENCODE"]) {
      assert.ok(!once.includes(spelling), `${spelling} left: ${once}`);
    }
  }
});

test("powered-by clause keeps the next env block removable", () => {
  const clause =
    "You are powered by claude-opus-4-6, a large language model trained by Meta MSL.";
  const preamble =
    "Here is some useful information about the environment you are running in:";
  const block = "<env>\n  Platform: darwin\n</env>";

  const joined = scrub(`Preamble line. ${clause}\n${preamble}\n${block}\nTrailing.`);
  assert.ok(joined.includes("Preamble line."), joined);
  assert.ok(!joined.includes("<env>"), joined);
  assert.ok(!joined.includes("environment you are running"), joined);

  const orphaned = scrub(`PRE. ${clause}\n${block}`);
  assert.ok(!orphaned.includes("<env>"), orphaned);
  assert.ok(orphaned.includes("PRE."), orphaned);

  const heading = scrub(`Some preamble. ${clause}\n# Communication`);
  assert.ok(heading.includes("\n# Communication"), heading);
});

test("powered-by clause survives clause reword", () => {
  const inputs = [
    "You are powered by X, built by Meta MSL. Tail stays.",
    "You are powered by X; trained by Meta. Tail stays.",
  ];
  for (const input of inputs) {
    const out = scrub(input);
    assert.ok(!out.includes("Meta"), out);
    assert.ok(out.includes("Tail stays."), out);
  }
});

test("env block removed", () => {
  const input = `Preamble line.\n${ENV_BLOCK}\n${ENV_BLOCK_CHANGED}\nTrailing note.`;
  const out = scrub(input);
  assert.ok(!out.includes("<env>"));
  assert.ok(!out.includes("Here is some useful information about the environment"));
  assert.ok(!out.includes("The environment you are running in is now:"));
  assert.ok(out.includes("Trailing note."));
  assert.equal(scrub(out), out);
  assert.equal(scrub("<env>\n  Platform: darwin\n</env>"), "");
  assert.equal(scrub(`${ENV_BLOCK_CHANGED}\n`), "");
});

test("composed chain: third-party scrub first, then ours", async () => {
  const thirdParty =
    "/Users/naphat/.config/meridian/node_modules/" +
    "@rynfar/meridian-plugin-opencode-scrub/dist/scrub.js";
  if (!existsSync(thirdParty)) {
    assert.fail(
      `Layer-A scrub package absent: ${thirdParty}. ` +
        "Kept only for this test; reinstall it or the regression goes unguarded.",
    );
  }
  const { scrubOpencodeFingerprints } = await import(thirdParty);
  const input = [
    CAPITAL_IDENTITY,
    LOWERCASE_IDENTITY,
    HARNESS_IDENTITY,
    TOOL_USE_HEADER,
    ENV_BLOCK,
    ENV_BLOCK_CHANGED,
    PRESERVE.join(" "),
  ].join("\n");
  // Composed order simulates Layer A in opencode; meridian runs only our plugin.
  const out = scrub(scrubOpencodeFingerprints(input));
  assert.ok(!out.includes("Meta MSL"), out);
  assert.ok(!out.includes("the assistant Specifics"), out);
  assert.ok(!out.includes("running in the assistant,"), out);
  assert.ok(!out.includes("You are the assistant, a coding agent"), out);
  assert.ok(!out.includes("interactive CLI tool"), out);
  assert.ok(!out.includes("<env>"), out);
  assert.ok(!out.includes("The environment you are running in is now:"), out);
  assert.ok(!out.includes("OpenCode"), out);
  for (const s of PRESERVE) {
    assert.ok(out.includes(s), `lost: ${s}`);
  }
  assert.equal(scrub(out), out);
  // Idempotent under the Layer-A scrub too: re-scrubbing our output is a no-op.
  assert.equal(scrubOpencodeFingerprints(out), out);
});

test("bare capital brand becomes the assistant", () => {
  const out = scrub("OpenCode ships with a built-in theme engine.");
  assert.ok(!out.includes("OpenCode"));
  assert.ok(out.includes("the assistant"));
});

test("lowercase references preserved", () => {
  const input =
    "Edit opencode.json and opencode.jsonc, then run opencode mcp add. " +
    "See https://opencode.ai/v2/docs and ~/.config/opencode/themes/.";
  const out = scrub(input);
  for (const s of PRESERVE) {
    assert.ok(out.includes(s), `lost: ${s}`);
  }
});

test("idempotent on the big fixture", () => {
  const big = [
    CAPITAL_IDENTITY,
    LOWERCASE_IDENTITY,
    HARNESS_IDENTITY,
    TOOL_USE_HEADER,
    V1_IDENTITY,
    ENV_BLOCK,
    REWORDED_IDENTITY,
    LOWER_REWORDED,
    CASE_VARIANTS,
    CASE_DRIFT_IDENTITY,
    PRESERVE.join(" "),
  ].join("\n");
  const once = scrub(big);
  assert.equal(scrub(once), once);
  assert.equal(scrub(scrub(once)), once);
});

test("onRequest never returns undefined", () => {
  const empty = plugin.onRequest({});
  assert.equal(typeof empty, "object");
  assert.notEqual(empty, null);

  const clean = plugin.onRequest({ systemContext: "You are a helpful assistant. Be concise." });
  assert.ok(clean);

  const dirty = plugin.onRequest({
    systemContext: `${TOOL_USE_HEADER}\n${LOWERCASE_IDENTITY}`,
  });
  assert.ok(dirty);
  assert.equal(typeof dirty.systemContext, "string");
  assert.ok(!dirty.systemContext.includes("OpenCode"));
  assert.ok(!dirty.systemContext.includes("interactive CLI tool"));
});

test("drift guard: identity needles in live binary", (t) => {
  const bin = "/Users/naphat/.opencode/bin/opencode";
  if (!existsSync(bin)) {
    t.skip("binary absent");
    return;
  }
  const buf = readFileSync(bin);
  const needles = [
    { text: CAPITAL_IDENTITY, residues: ["Meta MSL"] },
    { text: LOWERCASE_IDENTITY, residues: ["interactive CLI tool"] },
    {
      text: "You are an AI agent running in OpenCode, a coding agent harness.",
      residues: ["running in the assistant,"],
    },
    { text: TOOL_USE_HEADER, residues: ["Specifics"] },
    {
      text: "Here is some useful information about the environment you are running in:",
      residues: ["<env>"],
      env: true,
    },
    {
      text: "The environment you are running in is now:",
      residues: ["<env>"],
      env: true,
    },
  ];
  const missing = needles
    .map((n) => n.text)
    .filter((text) => !buf.includes(Buffer.from(text)));
  assert.deepEqual(
    missing,
    [],
    `identity needles absent from binary, drift detected: ${missing.join(" || ")}`,
  );
  for (const needle of needles) {
    const input = needle.env
      ? `Context line.\n${needle.text}\n<env>\n  Platform: darwin\n</env>\n`
      : `${needle.text}\n`;
    const out = scrub(input);
    assert.ok(!out.includes(needle.text), `needle survived "${needle.text}": ${out}`);
    assert.ok(!out.includes("OpenCode"), `brand left for "${needle.text}": ${out}`);
    for (const residue of needle.residues) {
      assert.ok(!out.includes(residue), `residue "${residue}" left: ${out}`);
    }
  }
});
