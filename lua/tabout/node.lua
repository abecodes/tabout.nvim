local utils = require('tabout.utils')
local config = require('tabout.config')
local logger = require('tabout.logger')

---@class TaboutNode
local M = {}

-- should be get_one_line and get_multi_line

---returns TSNode if node has a valid parent, else nil
---@param node TSNode
---@param multi boolean
---@return TSNode?
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
---@return TSNode?
M.get_node_at_cursor = function(dir)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1
    local col = dir == 'backward' and cursor[2] and cursor[2] - 1 or cursor[2]
    local cursor_range = {line, col, line, col}
    local ok, parser = pcall(vim.treesitter.get_parser, 0)
    if ok and parser then
      parser:parse()
    else
        logger.debug("get_node_at_cursor: No parser found for filetype " .. vim.bo[0].filetype)
        return
    end
    local tree = parser:tree_for_range(cursor_range)
    local root = tree and tree:root()

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
---@param node TSNode
---@param dir string | "'forward'" | "'backward'"
---@param multi boolean
---@return integer?
---@return integer?
---@return integer?
M.get_tabout_position = function(node, dir, multi)
    if type(node) ~= 'userdata' or node == 'nil' then
        logger.debug("get_tabout_position: no node supplied")
        return nil, nil
    end

    if M.is_wrapped(node) then
        if multi or M.is_one_line(node) then
            logger.debug("is wrapped node")
            if dir == 'backward' then return node:start() end
            return node:end_()
        else
            if dir == 'backward' and M.starts_on_same_line(node) then
                return node:start()
            end
        end
    end

    if not config.options.ignore_beginning then
        logger.debug("ignoring beginning")
        return nil, nil
    end

    -- if dir == 'backward' then
    --     local text = vim.treesitter.get_node_text(node)
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
---@param node TSNode
M.is_wrapped = function(node)
    local text = vim.split(vim.treesitter.get_node_text(node, 0), '\n')
    if type(next(text)) ~= 'nil' then
        local first = string.sub(text[1], 1, 1)
        local last = string.sub(text[#text], -1)

        logger.debug('wrapped with: ' .. first .. last)
        return config.tabouts[first] == last
    end

    return false
end

---@return boolean
---@param node TSNode
M.starts_on_same_line = function(node)
    local start_line, _, _, _ = node:range()
    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1

    return start_line == current_line
end

---@return boolean
---@param node TSNode
M.is_one_line = function(node)
    local start_line, _, end_line, _ = node:range()

    return start_line == end_line
end

---Scann a node`s text for combos
---@param node TSNode
---@return integer?
---@return integer?
M.scan_text = function(node, dir)
    -- just scan on current line
    local parent = node:parent()
    if not parent or M.is_one_line(parent) then
        parent = node
    end
    ---@diagnostic disable-next-line: need-check-nil, param-type-mismatch
    while (parent:parent() and M.is_one_line(parent:parent())) do
        parent = parent:parent()
    end
    ---@cast parent TSNode
    logger.debug('scanning text inside ' .. parent:type() .. ' node')
    text = vim.treesitter.get_node_text(parent, 0)

    if (utils.str_is_empty(text)) then
        return nil, nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local current_cursor_line = cursor[1]
    local current_cursor_row = cursor[2]
    local _, node_start = parent:start()
    local _, node_end = parent:end_()

    if dir == 'backward' then
        current_cursor_row = current_cursor_row-1
    end

    if dir == 'backward' then
        text = string.sub(text, 1, current_cursor_row-node_end)
    else
        text = string.sub(text, current_cursor_row-node_start)
    end

    logger.debug("substring: " .. text)

    local iter = 0
    local line = nil
    local col = nil

    text:gsub(".", function(c)

        for _, combo in pairs(config.options.tabouts) do
            if dir == 'backward' then
                if combo.open == c then
                    line = current_cursor_line - 1
                    col = node_start + iter
                    return
                end
            else
                if combo.close == c then
                    line = current_cursor_line - 1
                    col = current_cursor_row + iter
                    return
                end
            end
        end
        iter = iter + 1
    end)

    return line, col
end

return M
