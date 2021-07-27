local api = vim.api
local ts_utils = require('nvim-treesitter.ts_utils')
local config = require('tabout.config')
local node = require('tabout.node')
local utils = require('tabout.utils')
local logger = require('tabout.logger')

local M = {}

local debug_node = function(line, col, node)
    if not node then logger.warn("No node at " .. line .. ":" .. col) end
    logger.warn(ts_utils.get_node_text(node)[1] .. ', ' .. tostring(line) ..
                    ', ' .. tostring(col) .. ', ' .. node:type())

    local parent = node:parent()
    if parent then
        logger.warn(
            ts_utils.get_node_text(parent)[1] .. ', ' .. tostring(line) .. ', ' ..
                tostring(col) .. ', ' .. parent:type())
    end
end

---@param dir string | "'forward'" | "'backward'"
local get_char_at_cursor_position = function(dir)
    local col = vim.api.nvim_win_get_cursor(0)[2]
    if col == 1 then return string.sub(vim.api.nvim_get_current_line(), 1, 1) end
    if dir == 'backward' then col = col - 1 end
    -- the hell do I know why thats not workig, althoug its the line, if col is greater 1 its nil
    -- local char = string.sub(vim.api.nvim_get_current_line(), col, 1)
    -- local char = vim.api.getline('.')[col]
    local line = vim.fn.getline('.')
    local substr = vim.fn.strpart(line, -1, col + 2)
    -- local substr = vim.fn.trim(substr)
    print(substr)
    local char = string.sub(substr, -1)
    if config.debug then
        logger.log("char is " .. char .. ", " .. type(char) .. ", " ..
                       string.len(char))
    end
    return char
end

local can_tabout = function()
    if vim.tbl_contains(config.options.exclude, vim.bo.filetype) then
        return false
    end

    if not api.nvim_win_is_valid(api.nvim_get_current_win()) then
        return false
    end

    return true
end

local forward_tab = function()
    if config.options.act_as_tab then
        api.nvim_command('cal feedkeys("' .. utils.replace("<C-V> <Tab>") ..
                             '", "n" )')
    end
end

local backward_tab = function()
    if config.options.act_as_shift_tab then
        api.nvim_command('cal feedkeys("' .. utils.replace("<C-V> <S-Tab>") ..
                             '", "n" )')
    end
end

M.forward = function(enabled)
    if config.debug then logger.log("forward") end
    if not enabled or not can_tabout() then return forward_tab() end
    if config.debug then logger.log("forward allowed") end

    local n = node.get_node_at_cursor()
    if not n then return forward_tab() end

    local line, col = node.get_tabout_position(n, 'forward')

    if not line then
        local node_start, node_end = n:end_()
        if config.debug then
            if config.debug then logger.warn("forward error") end
            debug_node(node_start, node_end, n)
        end

        return forward_tab()
    end

    return api.nvim_win_set_cursor(0, {line + 1, col})
end

M.backward = function(enabled)
    if config.debug then logger.log("backward") end
    if not enabled or not can_tabout() then return backward_tab() end
    if config.debug then logger.log("backward allowed") end

    local n = node.get_node_at_cursor("backward")
    if not n then return backward_tab() end

    local line, col = node.get_tabout_position(n, 'backward')

    if not line then
        local node_start, node_end = n:start()
        if config.debug then
            if config.debug then logger.warn("backward error") end
            debug_node(node_start, node_end, n)
        end

        local prev_char = get_char_at_cursor_position('backward')
        if prev_char == '' or prev_char == ' ' then return backward_tab() end
        return
    end
    return api.nvim_win_set_cursor(0, {line + 1, col})
end

return M
