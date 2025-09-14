local function get_pid_from_dap_pid_file()
  local search_base_dir = vim.fn.getcwd()
  local found_pid_file_path = nil

  found_pid_file_path = vim.fs.find("dap.pid", {
    path = search_base_dir,
    type = 'file',
    limit = 1,
  })[1]

  if not found_pid_file_path then
    vim.notify(
      "No dap.pid file found recursively in '" .. search_base_dir .. "'.",
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
      "Failed to read PID file '" .. found_pid_file_path .. "'. Error: " .. tostring(err_read),
      vim.log.levels.ERROR
    )
    return nil
  end

  if not pid_str or pid_str == "" then
    vim.notify(
      "PID file '" .. found_pid_file_path .. "' is empty or could not read its first line.",
      vim.log.levels.WARN
    )
    return nil
  end

  local pid = tonumber(pid_str:match("^%s*(%d+)%s*$"))
  if not pid then
    vim.notify(
      "Could not parse a valid PID number from the first line of '" ..
      found_pid_file_path .. "'. Content: '" .. pid_str:gsub("%s", " ") .. "'",
      vim.log.levels.WARN
    )
    return nil
  end

  vim.notify(
    "Successfully found and parsed PID: " .. pid .. " from '" .. found_pid_file_path .. "'.",
    vim.log.levels.INFO
  )
  return pid
end

local function get_venv_python()
  local cwd = vim.fn.getcwd()
  local venv_path = cwd .. "/.venv/bin/python"
  local readable = vim.fn.filereadable(venv_path)
  if readable == 1 then
    return venv_path
  else
    return "python3"
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "leoluz/nvim-dap-go",
      "mfussenegger/nvim-dap-python",
      "Joakker/lua-json5",
    },
    config = function()
      local dap_python = require("dap-python")
      local dap = require("dap")

      require('dap.ext.vscode').json_decode = require('json5').parse

      dap_python.setup(get_venv_python())
      table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'Launch file from pyproject root',
        program = '${file}',
        justMyCode = true,
        console = 'integratedTerminal',
        cwd = function()
          local file_path = vim.api.nvim_buf_get_name(0)
          if file_path == "" then
            vim.notify("No file detected in current buffer, using cwd: " .. vim.fn.getcwd())
            return vim.fn.getcwd()
          end

          local pyproject = vim.fs.find("pyproject.toml", {
            path = vim.fs.dirname(file_path),
            upward = true,
            type = "file",
            limit = 1,
          })[1]

          if pyproject then
            local pyproject_dir = vim.fs.dirname(pyproject)
            vim.notify("Using pyproject.toml parent dir as root at: " .. pyproject_dir)
            return pyproject_dir
          else
            vim.notify("No pyproject.toml found, using cwd: " .. vim.fn.getcwd())
            return vim.fn.getcwd()
          end
        end,
        env = { PYTHONPATH = "." }
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

      dap.adapters["pwa-chrome"] = {
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
            cwd = vim.fn.getcwd,
            console = "integratedTerminal",
            sourceMaps = true,
          },
          { -- Remember to use --insepct flag when attaching debugger to node
            type = "pwa-node",
            request = "attach",
            name = "Attach to process",
            processId = require("dap.utils").pick_process,
            console = "integratedTerminal",
            cwd = vim.fn.getcwd,
            sourceMaps = true,
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to PID using dap.pid",
            processId = get_pid_from_dap_pid_file,
            console = "integratedTerminal",
          },
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome",
            console = "integratedTerminal",
            url = function()
              local co = coroutine.running()
              return coroutine.create(function()
                vim.ui.input({ prompt = "Enter URL: ", default = "http://localhost:3000" }, function(url)
                  if url == nil or url == "" then
                    return
                  else
                    coroutine.resume(co, url)
                  end
                end)
              end)
            end,
            cwd = vim.fn.getcwd,
            sourceMaps = true,
            localRoot = vim.fn.getcwd,
            remoteRoot = function()
              local co = coroutine.running()
              return coroutine.create(function()
                vim.ui.input({ prompt = "Enter remote root: ", default = "/" }, function(remoteRoot)
                  if remoteRoot == nil or remoteRoot == "" then
                    return
                  else
                    coroutine.resume(co, remoteRoot)
                  end
                end)
              end)
            end,
            resolveSourceMapLocations = {
              "${workspaceFolder}/**",
            },
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
            processId = get_pid_from_dap_pid_file,
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

      dap.configurations.dart = {
        {
          type = "dart",
          request = "launch",
          name = "Launch dart",
          dartSdkPath = "dart",
          flutterSdkPath = "flutter",
          program = "${workspaceFolder}/lib/main.dart",
          cwd = "${workspaceFolder}",
        },
        {
          type = "flutter",
          request = "launch",
          name = "Launch flutter",
          dartSdkPath = "dart",
          flutterSdkPath = "flutter",
          program = "${workspaceFolder}/lib/main.dart",
          cwd = "${workspaceFolder}",
        }
      }

      -- Overriding dart adapter to just use flutter. This matches the VSCode behavior for others
      -- I will probably never write dart without flutter anyways.
      dap.adapters.dart = {
        type = 'executable',
        command = 'flutter',
        args = { 'debug_adapter' },
      }
      dap.adapters.flutter = {
        type = 'executable',
        command = 'flutter',
        args = { 'debug_adapter' },
      }
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
