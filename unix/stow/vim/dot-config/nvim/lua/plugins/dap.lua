local function get_pid_from_cwd_file()
  local search_base_dir = vim.fn.getcwd()
  local found_pid_file_path = nil

  found_pid_file_path = vim.fs.find("dap.pid", {
    path = search_base_dir,
    type = 'file',
    limit = 1,
  })[1]

  if not found_pid_file_path then
    vim.notify(
      "PID Parser INFO: No dap.pid file found recursively in '" .. search_base_dir .. "'.",
      vim.log.levels.INFO
    )
    return nil
  end

  local pid_str = nil
  local success_read, err_read = pcall(function()
    local file = io.open(found_pid_file_path, "r")
    if file then
      pid_str = file:read("*l") -- Read the first line
      file:close()
    end
  end)

  if not success_read then
    vim.notify(
      "PID Parser ERROR: Failed to read PID file '" .. found_pid_file_path .. "'. Error: " .. tostring(err_read),
      vim.log.levels.ERROR
    )
    return nil
  end

  if not pid_str or pid_str == "" then
    vim.notify(
      "PID Parser WARNING: PID file '" .. found_pid_file_path .. "' is empty or could not read its first line.",
      vim.log.levels.WARN
    )
    return nil
  end

  local pid = tonumber(pid_str:match("^%s*(%d+)%s*$"))
  if not pid then
    vim.notify(
      "PID Parser WARNING: Could not parse a valid PID number from the first line of '" ..
      found_pid_file_path .. "'. Content: '" .. pid_str:gsub("%s", " ") .. "'",
      vim.log.levels.WARN
    )
    return nil
  end

  vim.notify(
    "PID Parser INFO: Successfully found and parsed PID: " .. pid .. " from '" .. found_pid_file_path .. "'.",
    vim.log.levels.INFO
  )
  return pid
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "leoluz/nvim-dap-go",
      "mfussenegger/nvim-dap-python",
    },
    config = function()
      local dap_python = require("dap-python")
      local dap = require("dap")

      dap_python.setup("python3")
      table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'PDM Launch from cwd',
        program = '${file}',
        python = 'pdm run',
        cwd = vim.fn.getcwd(),
        -- ... more options, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
      })

      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "js-debug-adapter",
          args = { "${port}" },
        }
      }

      for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = vim.fn.getcwd(),
            console = "integratedTerminal",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process",
            processId = require("dap.utils").pick_process,
            console = "integratedTerminal",
          },
        }
      end


      local dap_go = require("dap-go")
      dap_go.setup({
        dap_configurations = {
          {
            type = "go",
            name = "Attach PID using dap.pid",
            mode = "local",
            request = "attach",
            processId = get_pid_from_cwd_file,
            console = "integratedTerminal",
          },
        },
        -- delve configurations
        delve = {
          -- the path to the executable dlv which will be used for debugging.
          -- by default, this is the "dlv" executable on your PATH.
          path = "dlv",
          -- time to wait for delve to initialize the debug session.
          -- default to 20 seconds
          initialize_timeout_sec = 20,
          -- a string that defines the port to start delve debugger.
          -- default to string "${port}" which instructs nvim-dap
          -- to start the process in a random available port.
          -- if you set a port in your debug configuration, its value will be
          -- assigned dynamically.
          port = "${port}",
          -- additional args to pass to dlv
          args = {},
          -- the build flags that are passed to delve.
          -- defaults to empty string, but can be used to provide flags
          -- such as "-tags=unit" to make sure the test suite is
          -- compiled during debugging, for example.
          -- passing build flags using args is ineffective, as those are
          -- ignored by delve in dap mode.
          -- avaliable ui interactive function to prompt for arguments get_arguments
          build_flags = {},
          -- whether the dlv process to be created detached or not. there is
          -- an issue on delve versions < 1.24.0 for Windows where this needs to be
          -- set to false, otherwise the dlv server creation will fail.
          -- avaliable ui interactive function to prompt for build flags: get_build_flags
          detached = vim.fn.has("win32") == 0,
          -- the current working directory to run dlv from, if other than
          -- the current working directory.
          cwd = nil,
        },
        -- options related to running closest test
        tests = {
          -- enables verbosity when running the test.
          verbose = false,
        },
      })
    end
  },
  { "rcarriga/nvim-dap-ui", enabled = false },
  {
    "miroshQa/debugmaster.nvim",
    -- osv is needed if you want to debug neovim lua code. Also can be used
    -- as a way to quickly test-drive the plugin without configuring debug adapters
    dependencies = { "mfussenegger/nvim-dap", "jbyuki/one-small-step-for-vimkind", },
    config = function()
      local dm = require("debugmaster")
      -- make sure you don't have any other keymaps that starts with "<leader>d" to avoid delay
      -- Alternative keybindings to "<leader>d" could be: "<leader>m", "<leader>;"
      vim.keymap.set({ "n", "v" }, "<leader>d", dm.mode.toggle, { nowait = true })
      -- If you want to disable debug mode in addition to leader+d using the Escape key:
      vim.keymap.set("n", "<Esc>", dm.mode.disable)
      -- This might be unwanted if you already use Esc for ":noh"
      vim.keymap.set("t", "<C-\\>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

      dm.plugins.osv_integration.enabled = true -- needed if you want to debug neovim lua code
      -- local dap = require("dap")
      -- Configure your debug adapters here
      -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
    end
  },
}
