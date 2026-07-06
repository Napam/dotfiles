vim.pack.add({
  { src = "https://github.com/folke/persistence.nvim" },
})

vim.opt.sessionoptions = { "buffers", "curdir", "folds", "help", "localoptions", "winpos", "winsize" }

-- branch = false: key sessions by directory only. With branch keying (the
-- default) a project's session fragments across git branches, and the branch is
-- only detected when cwd is exactly the git root. One session per dir matches
-- the reliable behavior on main-branch projects.
require("persistence").setup({ branch = false })

-- Clean up hidden buffers before saving a session
local function delete_hidden_buffers()
  local visible = {}
  for _, win in pairs(vim.api.nvim_list_wins()) do
    visible[vim.api.nvim_win_get_buf(win)] = true
  end
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    if not visible[buf] and vim.api.nvim_buf_is_valid(buf) then
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
      if buftype == "" then
        pcall(vim.api.nvim_buf_delete, buf, {})
      end
    end
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceSavePre",
  group = vim.api.nvim_create_augroup("persistence_user", { clear = true }),
  callback = delete_hidden_buffers,
})
