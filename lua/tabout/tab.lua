local api = vim.api
local ts_utils = require('nvim-treesitter.ts_utils')
local config = require('tabout.config')
local node = require('tabout.node')
local utils = require('tabout.utils')
local logger = require('tabout.logger')

local M = {}

local debug_node = function(line, col, node)
    if not node then logger.warn("No node at " .. line .. ":" .. col) end
    local text = ts_utils.get_node_text(node)
    logger.warn(text[1] .. ', ' .. tostring(line) .. ', ' .. tostring(col) ..
                    ', ' .. node:type() .. ', ' .. text[#text])

    local parent = node:parent()
    if parent then
        local text = ts_utils.get_node_text(parent)
        logger.warn(
            text[1] .. ', ' .. tostring(line) .. ', ' .. tostring(col) .. ', ' ..
                parent:type() .. ', ' .. text[#text])
    end
end

-- TODO: rework, could work with smth like 'am i in a node? is my position at the beginning or end of it?'
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
    local char = string.sub(substr, -1)
    logger.debug("char is " .. char .. ", " .. type(char) .. ", " ..
                     string.len(char))
    return char
end

local can_tabout = function()
    -- TODO: check filetype on buffenter and enable/disable there
    if vim.tbl_contains(config.options.exclude, vim.bo.filetype) then
        return false
    end

    return api.nvim_win_is_valid(api.nvim_get_current_win())
end

local forward_tab = function()
    logger.debug("tabbing forward")
    if config.options.act_as_tab then
        api.nvim_command('cal feedkeys("' .. utils.replace("<C-V> <Tab>") ..
                             '", "n" )')
    end
end

local backward_tab = function()
    logger.debug("tabbing backward " ..
                     tostring(config.options.act_as_shift_tab))

    local prev_char = get_char_at_cursor_position('backward')
    if config.options.act_as_shift_tab and (prev_char == '' or prev_char == ' ') then
        api.nvim_command('cal feedkeys("' .. utils.replace("<C-V> <S-Tab>") ..
                             '", "n" )')
    end
end

---@param dir string | "'forward'" | "'backward'"
---@param enabled boolean
---@param multi boolean
M.tabout = function(dir, enabled, multi)
    local tab_action

    if dir == 'forward' then
        tab_action = forward_tab
    else
        tab_action = backward_tab
    end

    logger.debug(dir)
    if not enabled or not can_tabout() then return tab_action() end
    logger.debug(dir .. " allowed")

    local n = node.get_node_at_cursor(dir)
    -- no need to tabout if we are on root level
    if not n or not n:parent() then return tab_action() end

    local line, col = node.get_tabout_position(n, dir, multi)

    -- just trigger the tab action if there is no target for a tabout
    if not line then
        if config.debug then
            local node_line, node_col = nil, nil
            if dir == 'forward' then
                node_line, node_col = n:end_()
            else
                node_line, node_col = n:start()
            end
            logger.debug(dir .. " error")
            if config.debug then debug_node(node_line, node_col, n) end
        end

        return tab_action()
    end

    if api.nvim_get_mode().mode == 'ic' then
      -- stop ins-completion without side-effects
      api.nvim_feedkeys(utils.replace('<C-G><C-G>'), 'ni', true)
    end
    return api.nvim_win_set_cursor(0, {line + 1, col})
end

return M
