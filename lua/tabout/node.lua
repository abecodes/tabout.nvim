local ts_utils = require('nvim-treesitter.ts_utils')
local utils = require('tabout.utils')
local config = require('tabout.config')
local logger = require('tabout.logger')

---@class TaboutNode
local M = {}

-- should be get_one_line and get_multi_line

---returns Node if node has a valid parent, else nil
---@param node Node
---@param multi boolean
---@return integer
---@return integer
local get_parent_node = function(node, multi)
    local parent = node:parent()

    --[[ iterate over parent nodes until no more nodes, no node on the same line
                or a wrapped node is encountered ]]
    while (parent and not M.is_wrapped(parent)) do
        if not multi and not M.is_one_line(parent) then break end
        parent = parent:parent()
    end

    if parent and M.is_wrapped(parent) then
        if not multi and not M.is_one_line(parent) then return nil end
        return parent
    else
        return nil
    end
end

---returns line,col or nil,nil
---@param dir string | "'forward'" | "'backward'"
---@return integer
---@return integer
M.get_node_at_cursor = function(dir)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local cursor_range = {cursor[1] - 1, cursor[2]}
    if dir == 'backward' and cursor[2] then
        cursor_range = {cursor[1] - 1, cursor[2] - 1}
    end
    local root =
        ts_utils.get_root_for_position(cursor_range[1], cursor_range[2])

    if not root then
        logger.debug(
            "get_node_at_cursor: no root found at " .. cursor_range[1] .. ":" ..
                cursor_range[2])
        return
    end

    logger.debug(
        "get_node_at_cursor: root found at " .. cursor_range[1] .. ":" ..
            cursor_range[2] .. ", " ..
            root:named_descendant_for_range(cursor_range[1], cursor_range[2],
                                            cursor_range[1], cursor_range[2])
                :type())

    return root:named_descendant_for_range(cursor_range[1], cursor_range[2],
                                           cursor_range[1], cursor_range[2])
end

---returns line,col or nil,nil
---@param node Node
---@param dir string | "'forward'" | "'backward'"
---@param multi boolean
---@return integer
---@return integer
M.get_tabout_position = function(node, dir, multi)
    if type(node) ~= 'userdata' then
        logger.debug("get_tabout_position: no node supplied")
        return nil, nil
    end

    if M.is_wrapped(node) then
        if multi or M.is_one_line(node) then
            logger.debug("is wrapped node")
            if dir == 'backward' then return node:start() end
            return node:end_()
        end
    end

    if not config.options.ignore_beginning then
        logger.debug("ignoring beginning")
        return nil, nil
    end

    -- if dir == 'backward' then
    --     local text = ts_utils.get_node_text(node)
    --     logger.debug(text[1] .. ', ' .. tostring(node:end_()) .. ', ' ..
    --                      tostring(node:end_()) .. ', ' .. node:type() .. ', ' ..
    --                      text[#text])
    -- end

    -- if cursor is at the beginning of the node look for wrapped parents
    if dir == 'backward' and utils.is_cursor_at_position(node:end_()) or
        utils.is_cursor_at_position(node:start()) then
        local parent = get_parent_node(node, multi)

        if parent then
            if dir == 'forward' then return parent:end_() end

            return parent:start()
        end
    end

    -- nothing parseable was found, try scanning the text on current line
    if M.is_one_line(node) then
        return M.scan_text(node, dir)
    end

    return nil, nil
end

---@return boolean
---@param node Node
M.is_wrapped = function(node)
    local text = ts_utils.get_node_text(node)
    if type(next(text)) ~= 'nil' then
        local first = string.sub(text[1], 1, 1)
        local last = string.sub(text[#text], -1)

        logger.debug('wrapped with: ' .. first .. last)
        return config.tabouts[first] == last
    end

    return false
end

---@return boolean
---@param node Node
M.is_one_line = function(node)
    local start_line, _, end_line, _ = node:range()

    return start_line == end_line
end

---Scann a node`s text for combos
---@param node Node
---@return integer
---@return integer
M.scan_text = function(node, dir)
    -- just scan on current line
    local parent = node:parent()
    if not M.is_one_line(parent) then
        parent = node
    end
    while (parent:parent() and M.is_one_line(parent:parent())) do
        parent = parent:parent()
    end
    logger.debug('scanning text inside ' .. parent:type() .. ' node')
    text = ts_utils.get_node_text(parent)
    if type(next(text)) ~= "nil" then
        if dir == 'backward' then
            text = string.sub(text[1], 1, vim.api.nvim_win_get_cursor(0)[2]-1)
        else
            text = string.sub(text[1], vim.api.nvim_win_get_cursor(0)[2])
        end

        iter = 0
        cursor = vim.api.nvim_win_get_cursor(0)
        line = nil
        col = nil

        text:gsub(".", function(c)

            for _, combo in pairs(config.options.tabouts) do
                if dir == 'backward' then
                    if combo.open == c then
                        line = cursor[1] - 1
                        col = iter + 1
                        return
                    end
                else
                    if combo.close == c then
                        line = cursor[1] - 1
                        col = cursor[2] + iter + 1
                        return
                    end
                end
            end
            iter = iter + 1
        end)

        return line, col
    end
    return nil, nil
end

return M
