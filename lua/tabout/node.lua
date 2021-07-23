local ts_utils = require('nvim-treesitter.ts_utils')
local utils = require('tabout.utils')
local config = require('tabout.config')

---@class TaboutNode
local M = {}

---returns line,col or nil,nil
---@param node Node
---@return integer
---@return integer
M.get_tabout_position = function(node)
    if M.is_one_line(node) then
        if M.is_wrapped(node) then
            return node:end_()
        else
            if not config.options.ignore_beginning then
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
