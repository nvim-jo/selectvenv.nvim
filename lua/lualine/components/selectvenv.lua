local M = require('lualine.component'):extend()

local default_opts = {
  icon = "",
  color = { fg = "#CDD6F4" },
  on_click = function()
    require('selectvenv').open()
  end,
}

function M:init(options)
  options = vim.tbl_deep_extend("keep", options or {}, default_opts)
  M.super.init(self, options)
end

function M:update_status()
  local venv = require('selectvenv').get_active_venv()
  if venv then
    local parts = vim.fn.split(venv, "/")
    local lastPart = parts[#parts]
    return lastPart
  else
    return 'Select Virtual Environment'
  end
end

return M