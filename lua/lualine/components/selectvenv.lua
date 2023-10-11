local M = require('lualine.component'):extend()

local default_opts = {
  icon = "",
  color = { fg = "#CDD6F4" },
}

function M:init(options)
  options = vim.tbl_deep_extend("keep", options or {}, default_opts)
  M.super.init(self, options)
end

function M:on_click()
  return require('selectvenv').open()
end

function M:update_status()
  local venv = require('selectvenv').get_active_venv()
  if venv then
    local parts = vim.fn.split(venv, "/")
    local lastPart = parts[#parts]
    return lastPart
  else
    return 'Select Venv'
  end
end

return M