local ts_utils = require('nvim-treesitter.ts_utils')
local utils = require('tabout.utils')
local config = require('tabout.config')
local logger = require('tabout.logger')

---@class TaboutNode
local M = {}

---returns line,col or nil,nil
---@param dir string | "'forward'" | "'backward'"
---@return integer
---@return integer
M.get_node_at_cursor = function(dir)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local cursor_range = {cursor[1] - 1, cursor[2]}
    if dir == 'backward' then cursor_range = {cursor[1] - 1, cursor[2] - 1} end
    local root = ts_utils.get_root_for_position(unpack(cursor_range))

    if not root then
        if config.debug then
            logger.warn("get_node_at_cursor : no root found at " ..
                            cursor_range[1] .. ":" .. cursor_range[2])
        end
        return
    end

    return root:named_descendant_for_range(cursor_range[1], cursor_range[2],
                                           cursor_range[1], cursor_range[2])
end

---returns line,col or nil,nil
---@param node Node
---@param dir string | "'forward'" | "'backward'"
---@return integer
---@return integer
M.get_tabout_position = function(node, dir)
    if type(node) ~= 'userdata' then
        if config.debug then
            logger.warn("get_tabout_position: no node supplied")
        end
        return nil, nil
    end
    if M.is_one_line(node) then
        if M.is_wrapped(node) then
            if dir == 'backward' then return node:start() end
            return node:end_()
        else
            if not config.options.ignore_beginning then
                if config.debug then
                    logger.log("ignoring beginning")
                end
                return nil, nil
            end
            -- if cursor is at the beginning of the node look for wrapped parents
            if utils.is_cursor_at_position(node:start()) then
                local parent = node:parent()

                --[[ iterate over parent nodes until no more nodes, no node on the same line
                    or a wrapped node is encountered ]]
                while (parent and M.is_one_line(parent) and
                    not M.is_wrapped(parent)) do
                    parent = parent:parent()
                end

                if parent and M.is_wrapped(parent) then
                    if dir == 'backward' then
                        return parent:start()
                    end
                    return parent:end_()
                else
                    return nil, nil
                end
            else
                return nil, nil
            end
        end
    else
        return nil, nil
    end
end

---@return boolean
---@param node Node
M.is_wrapped = function(node)
    local text = ts_utils.get_node_text(node)
    if type(next(text)) ~= "nil" then
        local first = string.sub(text[1], 1, 1)
        local last = string.sub(text[1], -1)

        if config.tabouts[first] == last then return true end

        return false
    end

    return false
end

---@return boolean
---@param node Node
M.is_one_line = function(node)
    local start_line, _, end_line, _ = node:range()

    return start_line - end_line == 0
end

return M
