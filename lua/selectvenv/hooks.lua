local lspconfig = require("lspconfig")

local M = {}


--- @alias NvimLspClient table
--- @alias LspClientCallback fun(client: NvimLspClient): nil
--- @type fun(name: string, callback: LspClientCallback): nil
function M.execute_for_client(name, callback)
  local dbg = require("selectvenv.utils").dbg
  local client = vim.lsp.get_active_clients({ name = name })[1]

  if not client then
    dbg("No client named: " .. name .. " found")
    return
  end

  callback(client)
end

--- @alias VenvChangedHook fun(venv_path: string, venv_python: string): nil
--- @type VenvChangedHook
function M.pyright_hook(_, venv_python)
  M.execute_for_client("pyright", function(pyright)
    local utils = require("selectvenv.utils")
    local settings = vim.deepcopy(pyright.config.settings)
    lspconfig.pyright.setup({
      settings = settings,
      before_init = function(_, c)
        c.settings.python.pythonPath = venv_python
        utils.dbg("Pyright settings:")
        utils.dbg(c.settings)
      end,
    })
  end)
end

--- @type VenvChangedHook
function M.pylance_hook(_, venv_python)
  M.execute_for_client("pylance", function(pylance)
    local settings = vim.deepcopy(pylance.config.settings)
    lspconfig.pylance.setup({
      settings = settings,
      before_init = function(_, c)
        c.settings.python.pythonPath = venv_python
      end,
    })
  end)
end

--- @type VenvChangedHook
function M.pylsp_hook(venv_path, _)
  local utils = require("selectvenv.utils")
  local system = require("selectvenv.system")
  local sys = system.get_info()

  M.execute_for_client("pylsp", function(pylsp)
    local settings = vim.deepcopy(pylsp.config.settings)
    local lib_path = venv_path .. sys.path_sep .. "lib" .. sys.path_sep
    local site_packages = nil

    for filename, _ in vim.fs.dir(lib_path) do
      if utils.starts_with(filename, "python") then
        site_packages = lib_path .. sys.path_sep .. filename .. sys.path_sep .. "site-packages"
      end
    end

    if site_packages == nil then
      utils.dbg("Failed to find site packages directory in: " .. lib_path)
      return
    end

    lspconfig.pylsp.setup({
      settings = settings,
      before_init = function(_, c)
        local jedi_config = settings.pylsp.plugins.jedi or {}

        if jedi_config.extra_paths ~= nil then
          table.insert(jedi_config.extra_paths, site_packages)
        else
          jedi_config["extra_paths"] = { site_packages }
        end

        c.settings.pylsp.plugins.jedi = jedi_config
      end,
    })
  end)
end

return M
