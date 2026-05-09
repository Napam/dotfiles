-- WARN: detection keyed by exepath — runs once per unique golangci-lint binary.
-- golangci-lint v1 vs v2 (v2 replaced `--out-format=json` with `--output.json.path=stdout`).
local cache = {} ---@type table<string, string[]>

local function detect_command()
  local exe = vim.fn.exepath("golangci-lint")
  if exe == "" then
    return { "golangci-lint", "run", "--output.json.path=stdout", "--show-stats=false" }
  end
  if cache[exe] then
    return cache[exe]
  end

  local v1, v2 = false, false
  -- PERF: `golangci-lint version` is ~0.1s; `go version -m` reads the binary's build info.
  if vim.fn.executable("go") == 1 then
    local out = vim.system({ "go", "version", "-m", exe }):wait(2000).stdout or ""
    v1 = string.match(out, "\tmod\tgithub.com/golangci/golangci%-lint\t") ~= nil
    v2 = string.match(out, "\tmod\tgithub.com/golangci/golangci%-lint/v2\t") ~= nil
  end
  if not v1 and not v2 then
    local out = vim.system({ "golangci-lint", "version" }):wait(2000).stdout or ""
    v1 = string.match(out, "version v?1%.") ~= nil
    v2 = string.match(out, "version v?2%.") ~= nil
  end

  local cmd
  if v1 then
    cmd = { "golangci-lint", "run", "--out-format", "json" }
  elseif v2 then
    cmd = { "golangci-lint", "run", "--output.json.path=stdout", "--show-stats=false" }
  else
    vim.notify("golangci-lint-ls: could not detect version, defaulting to v2 args", vim.log.levels.WARN)
    cmd = { "golangci-lint", "run", "--output.json.path=stdout", "--show-stats=false" }
  end
  cache[exe] = cmd
  return cmd
end

---@type vim.lsp.Config
return {
  cmd = { "golangci-lint-langserver" },
  filetypes = { "go", "gomod" },
  init_options = {},
  root_markers = {
    ".golangci.yml",
    ".golangci.yaml",
    ".golangci.toml",
    ".golangci.json",
    "go.mod",
    ".git",
  },
  before_init = function(_, config)
    config.init_options.command = detect_command()
  end,
}
