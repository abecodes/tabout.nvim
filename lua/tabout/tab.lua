local api = vim.api
local ts_utils = require('nvim-treesitter.ts_utils')
local config = require('tabout.config')
local node = require('tabout.node')
local utils = require('tabout.utils')
local logger = require('tabout.logger')

local can_tabout = function()
    if vim.tbl_contains(config.options.exclude, vim.bo.filetype) then
        return false
    end

    if not api.nvim_win_is_valid(api.nvim_get_current_win()) then
        return false
    end

    return true
end

local normal_tab = function()
    if config.options.act_as_tab then
        api.nvim_command('cal feedkeys("' .. utils.replace("<C-V> <Tab>") ..
                             '", "n" )')
    end
end

return function(enabled)
    if not enabled or not can_tabout() then return normal_tab() end

    local n = ts_utils.get_node_at_cursor()
    if not n then return normal_tab() end

    local line, col = node.get_tabout_position(n)

    if not line then
        if config.debug then
            local end_line, end_col = n:end_()

            logger.warn(ts_utils.get_node_text(n)[1] .. ', ' ..
                            tostring(end_line) .. ', ' .. tostring(end_col) ..
                            ', ' .. n:type())
            logger.warn(ts_utils.get_node_text(n:parent())[1] .. ', ' ..
                            tostring(end_line) .. ', ' .. tostring(end_col) ..
                            ', ' .. n:parent():type())
        end

        return normal_tab()
    end

    return api.nvim_win_set_cursor(0, {line + 1, col})
end
