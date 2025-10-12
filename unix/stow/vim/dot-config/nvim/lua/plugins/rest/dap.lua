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

local function get_venv_python(cwd)
  vim.notify("Looking for .venv in cwd: " .. cwd)
  local venv_dir = vim.fs.find(".venv", {
    path = cwd,
    upward = true,
    type = "directory",
    limit = 1,
  })[1]
  if venv_dir then
    vim.notify("Using venv python at: " .. venv_dir)
    return venv_dir .. "/bin/python"
  else
    return "python3"
  end
end

---@param dap table The 'dap' module (i.e., require('dap')).
local function setup_dap_python(dap)
  -- local dap_python = require("dap-python")
  -- dap_python.setup(get_venv_python())

  dap.adapters.python = function(callback, opts)
    local cwd = vim.fn.getcwd()
    if type(opts.cwd) == "function" then
      cwd = opts.cwd()
    else
      cwd = opts.cwd or cwd
    end

    local config = {
      type = 'executable',
      command = get_venv_python(cwd),
      args = { '-m', 'debugpy.adapter' },
      executable = {
        cwd = cwd,
      }
    }

    callback(config)
  end

  dap.configurations.python = {
    {
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
    }
  }
end


---@param dap table The 'dap' module (i.e., require('dap')).
local function setup_dap_js(dap)
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
end


---@param dap table The 'dap' module (i.e., require('dap')).
local function setup_dap_go(dap)
  dap.adapters.go = function(callback, config)
    local command = "dlv"
    local args = { "dap", "-l", "127.0.0.1:${port}" }

    if config.useKitty then
      -- Hack to see delve output, since delve is not sending output to nvim
      command = "kitty"
      args = { "dlv", "dap", "-l", "127.0.0.1:${port}" }
    end

    callback({
      type = "server",
      port = "${port}",
      executable = {
        command = command,
        args = args,
        detached = vim.fn.has("win32") == 0,
        cwd = config.cwd
      },
    })
  end

  dap.configurations.go = {
    {
      type = "go",
      name = "Attach PID using dap.pid",
      mode = "local",
      request = "attach",
      processId = get_pid_from_dap_pid_file,
      -- console = "integratedTerminal", no effect, delve does not support it, just look at the output of whatever is running the process
    },
    {
      type = "go",
      name = "Debug package by closest go.mod",
      request = "launch",
      useKitty = true,
      program = ".",
      cwd = function()
        local file_path = vim.api.nvim_buf_get_name(0)
        if file_path == "" then
          vim.notify("No file detected in current buffer, using cwd: " .. vim.fn.getcwd())
          return vim.fn.getcwd()
        end

        local go_mod = vim.fs.find("go.mod", {
          path = vim.fs.dirname(file_path),
          upward = true,
          type = "file",
          limit = 1,
        })[1]

        if go_mod then
          local go_mod_dir = vim.fs.dirname(go_mod)
          vim.notify("Using go.mod parent dir as root at: " .. go_mod_dir)
          return go_mod_dir
        else
          vim.notify("No go.mod found, using cwd: " .. vim.fn.getcwd())
          return vim.fn.getcwd()
        end
      end,
    },
    {
      type = "go",
      name = "Debug package by closest go.mod with args",
      request = "launch",
      useKitty = true,
      program = ".",
      args = function()
        local co = coroutine.running()
        return coroutine.create(function()
          vim.ui.input({ prompt = "Enter program arguments (space-separated): " }, function(input)
            if input == nil then
              coroutine.resume(co, {})
            else
              local args = {}
              for arg in string.gmatch(input, "%S+") do
                table.insert(args, arg)
              end
              coroutine.resume(co, args)
            end
          end)
        end)
      end,
      cwd = function()
        local file_path = vim.api.nvim_buf_get_name(0)
        if file_path == "" then
          vim.notify("No file detected in current buffer, using cwd: " .. vim.fn.getcwd())
          return vim.fn.getcwd()
        end

        local go_mod = vim.fs.find("go.mod", {
          path = vim.fs.dirname(file_path),
          upward = true,
          type = "file",
          limit = 1,
        })[1]

        if go_mod then
          local go_mod_dir = vim.fs.dirname(go_mod)
          vim.notify("Using go.mod parent dir as root at: " .. go_mod_dir)
          return go_mod_dir
        else
          vim.notify("No go.mod found, using cwd: " .. vim.fn.getcwd())
          return vim.fn.getcwd()
        end
      end,
    },
  }
end

---@param dap table The 'dap' module (i.e., require('dap')).
local function setup_dap_flutter(dap)
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
end


return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      -- "mfussenegger/nvim-dap-python",
      "Joakker/lua-json5",
    },
    config = function()
      local dap = require("dap")
      require('dap.ext.vscode').json_decode = require('json5').parse
      setup_dap_python(dap)
      setup_dap_js(dap)
      setup_dap_go(dap)
      setup_dap_flutter(dap)
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
