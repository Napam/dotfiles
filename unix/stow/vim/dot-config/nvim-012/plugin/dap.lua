if Config.only_essential_plugins() then return end

local function get_pid_from_dap_pid_file()
  local search_base_dir = vim.fn.getcwd()
  local found = vim.fs.find({ "dap.pid", "app.pid", "main.pid", "pid" }, {
    path = search_base_dir,
    type = "file",
    limit = 1,
  })[1]

  if not found then
    vim.notify("No dap.pid file found recursively in '" .. search_base_dir .. "'.", vim.log.levels.INFO)
    return nil
  end

  local pid_str
  local ok, err = pcall(function()
    local f = io.open(found, "r")
    if f then
      pid_str = f:read("*l")
      f:close()
    end
  end)
  if not ok then
    vim.notify("Failed to read PID file '" .. found .. "': " .. tostring(err), vim.log.levels.ERROR)
    return nil
  end
  if not pid_str or pid_str == "" then
    vim.notify("PID file empty: " .. found, vim.log.levels.WARN)
    return nil
  end
  local pid = tonumber(pid_str:match("^%s*(%d+)%s*$"))
  if not pid then
    vim.notify("Could not parse PID from '" .. found .. "'", vim.log.levels.WARN)
    return nil
  end
  vim.notify("Parsed PID " .. pid .. " from " .. found)
  return pid
end

-- Delve has no native envFile support (unlike debugpy/pwa-node); VSCode's Go
-- extension parses and merges before launch. Replicate here.
local function parse_env_file(filepath)
  local env = {}
  local f = io.open(filepath, "r")
  if not f then return env end
  for line in f:lines() do
    if not line:match("^%s*#") and not line:match("^%s*$") then
      local stripped = line:match("^%s*export%s+(.+)$") or line
      local key, val = stripped:match("^%s*([^%s=]+)%s*=%s*(.-)%s*$")
      if key and val then
        local quoted = val:match('^"(.*)"$') or val:match("^'(.*)'$")
        if quoted then
          -- Quoted: a `#` inside is part of the value, do NOT strip.
          val = quoted
        else
          val = val:match("^(.-)%s*#.*$") or val
        end
        env[key] = val
      end
    end
  end
  f:close()
  return env
end

local function get_venv_python(cwd)
  local venv_dir = vim.fs.find(".venv", {
    path = cwd,
    upward = true,
    type = "directory",
    limit = 1,
  })[1]
  if venv_dir then
    return venv_dir .. "/bin/python"
  end
  return "python3"
end

local function find_go_mod_dir()
  local file_path = vim.api.nvim_buf_get_name(0)
  if file_path == "" then return vim.fn.getcwd() end
  local go_mod = vim.fs.find("go.mod", {
    path = vim.fs.dirname(file_path),
    upward = true,
    type = "file",
    limit = 1,
  })[1]
  if go_mod then return vim.fs.dirname(go_mod) end
  return vim.fn.getcwd()
end

local function setup_dap_python(dap)
  local python_adapter = function(callback, opts)
    local cwd = vim.fn.getcwd()
    if type(opts.cwd) == "function" then
      cwd = opts.cwd()
    else
      cwd = opts.cwd or cwd
    end
    callback({
      type = "executable",
      command = get_venv_python(cwd),
      args = { "-m", "debugpy.adapter" },
      executable = { cwd = cwd },
    })
  end
  dap.adapters.python = python_adapter
  dap.adapters.debugpy = python_adapter

  local configs = {
    {
      type = "python",
      request = "launch",
      name = "Launch file from pyproject root",
      program = "${file}",
      justMyCode = true,
      console = "integratedTerminal",
      cwd = function()
        local file_path = vim.api.nvim_buf_get_name(0)
        if file_path == "" then return vim.fn.getcwd() end
        local pyproject = vim.fs.find("pyproject.toml", {
          path = vim.fs.dirname(file_path),
          upward = true,
          type = "file",
          limit = 1,
        })[1]
        if pyproject then return vim.fs.dirname(pyproject) end
        return vim.fn.getcwd()
      end,
      env = { PYTHONPATH = "." },
    },
  }
  dap.configurations.python = configs
  dap.configurations.debugpy = configs
end

local function setup_dap_js(dap)
  for _, kind in ipairs({ "pwa-node", "pwa-chrome" }) do
    dap.adapters[kind] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = "js-debug-adapter",
        args = { "${port}" },
      },
    }
  end

  for _, lang in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
    dap.configurations[lang] = {
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        cwd = vim.fn.getcwd,
        console = "integratedTerminal",
        sourceMaps = true,
      },
      {
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
              if url and url ~= "" then coroutine.resume(co, url) end
            end)
          end)
        end,
        cwd = vim.fn.getcwd,
        sourceMaps = true,
        localRoot = vim.fn.getcwd,
        remoteRoot = function()
          local co = coroutine.running()
          return coroutine.create(function()
            vim.ui.input({ prompt = "Enter remote root: ", default = "/" }, function(rr)
              if rr and rr ~= "" then coroutine.resume(co, rr) end
            end)
          end)
        end,
        resolveSourceMapLocations = { "${workspaceFolder}/**" },
      },
    }
  end
end

local function setup_dap_go(dap)
  dap.adapters.go = function(callback, config)
    local final_env = {}

    if config.envFile then
      local cwd = config.cwd or vim.fn.getcwd()
      local path = config.envFile
        :gsub("${workspaceFolder}", cwd)
        :gsub("${cwd}", cwd)
      if not path:match("^/") then
        path = cwd .. "/" .. path:gsub("^%./", "")
      end
      for k, v in pairs(parse_env_file(path)) do
        final_env[k] = tostring(v)
      end
    end

    if config.env then
      for k, v in pairs(config.env) do
        final_env[k] = tostring(v)
      end
    end
    config.env = final_env

    local command = "dlv"
    local args = { "dap", "-l", "127.0.0.1:${port}" }
    if config.useKitty then
      -- Hack: delve doesn't pipe output to nvim; route via kitty so output
      -- appears in a separate kitty window.
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
        cwd = config.cwd,
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
    },
    {
      type = "go",
      name = "Debug package by closest go.mod",
      request = "launch",
      useKitty = true,
      program = ".",
      cwd = function()
        local d = find_go_mod_dir()
        vim.notify("Using go.mod parent: " .. d)
        return d
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
      cwd = function() return find_go_mod_dir() end,
    },
    {
      type = "go",
      name = "Debug test by function under cursor",
      request = "launch",
      useKitty = true,
      mode = "test",
      cwd = "${fileDirname}",
      program = "${fileDirname}",
      args = function()
        -- Stable vim.treesitter API; the old nvim-treesitter.ts_utils path is
        -- removed on nvim-treesitter `main`. Requires the go parser.
        local ok_node, node = pcall(vim.treesitter.get_node)
        if not ok_node or not node then
          vim.notify("treesitter: no node at cursor (parser missing?)", vim.log.levels.WARN)
          return {}
        end
        while node do
          if node:type() == "function_declaration" then
            local name_node = node:field("name")[1]
            if name_node then
              local fn_name = vim.treesitter.get_node_text(name_node, 0)
              if fn_name:match("^Test") then
                vim.notify("Running test: " .. fn_name)
                return { "-test.run", "^" .. fn_name .. "$", "-test.v" }
              end
            end
          end
          node = node:parent()
        end
        vim.notify("No test function found under cursor", vim.log.levels.WARN)
        return {}
      end,
    },
    {
      type = "go",
      name = "Debug test by input function name",
      request = "launch",
      useKitty = true,
      mode = "test",
      cwd = "${fileDirname}",
      program = "${fileDirname}",
      args = function()
        local name = vim.fn.input("Test name: ")
        if name ~= "" then return { "-test.run", "^" .. name .. "$", "-test.v" } end
        return {}
      end,
    },
  }
end

local function setup_dap_flutter(dap)
  dap.adapters.dart = { type = "executable", command = "flutter", args = { "debug_adapter" } }
  dap.adapters.flutter = { type = "executable", command = "flutter", args = { "debug_adapter" } }

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
    },
  }
end

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/mfussenegger/nvim-dap" },
    { src = "https://github.com/jbyuki/one-small-step-for-vimkind" },
    { src = "https://github.com/miroshQa/debugmaster.nvim" },
  })

  local dap = require("dap")

  -- json5 launch.json support; only present if lua-json5 built (needs C compiler).
  local ok_json5, json5 = pcall(require, "json5")
  if ok_json5 then
    require("dap.ext.vscode").json_decode = json5.parse
  end

  setup_dap_python(dap)
  setup_dap_js(dap)
  setup_dap_go(dap)
  setup_dap_flutter(dap)

  local dm = require("debugmaster")
  vim.keymap.set({ "n", "v" }, "<leader>d", dm.mode.toggle, { nowait = true })
  vim.keymap.set("n", "<Esc>", dm.mode.disable)
  vim.keymap.set("t", "<C-\\>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

  dm.plugins.osv_integration.enabled = true
end)
