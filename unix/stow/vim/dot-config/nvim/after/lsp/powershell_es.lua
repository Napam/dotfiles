-- WARN: cmd must be a static table, not a function. validate_cmd then checks
-- executable("pwsh") and skips the server when pwsh is missing; a function
-- would spawn anyway and fail with a transport error. PSES is a module (no bin).
local function warn_pwsh_missing()
  if vim.fn.executable("pwsh") == 1 then
    return
  end
  local msg = "powershell_es disabled: pwsh not on PATH (mise powershell)"
  local ok, fidget = pcall(require, "fidget.notification")
  local notify = ok and fidget.notify or vim.notify
  notify(msg, vim.log.levels.WARN)
end

-- Config loads at VimEnter, after nvim-arg buffers fired FileType; warn on the
-- first ps1 buffer, open or future.
if vim.fn.executable("pwsh") ~= 1 then
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "ps1",
    group = vim.api.nvim_create_augroup("powershell-es-pwsh-warn", { clear = true }),
    once = true,
    callback = warn_pwsh_missing,
  })
  -- Already-open buffers (nvim arg) missed the FileType event.
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "ps1" then
      warn_pwsh_missing()
      break
    end
  end
end

local bundle_path = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "powershell-editor-services")
local temp_path = vim.fn.stdpath("cache")

local command_fmt =
  [[& '%s/PowerShellEditorServices/Start-EditorServices.ps1' -BundledModulesPath '%s' -LogPath '%s/powershell_es.log' -SessionDetailsPath '%s/powershell_es.session.json' -FeatureFlags @() -AdditionalModules @() -HostName nvim -HostProfileId 0 -HostVersion 1.0.0 -Stdio -LogLevel Warning]]

---@type vim.lsp.Config
return {
  -- HACK: lspconfig's cmd passes -LogLevel Normal, deprecated in PSES; use
  -- Warning (quiet; bump to Information/Debug to debug PSES).
  cmd = { "pwsh", "-NoLogo", "-NoProfile", "-Command", command_fmt:format(bundle_path, bundle_path, temp_path, temp_path) },
}
