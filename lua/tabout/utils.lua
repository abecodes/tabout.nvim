local api = vim.api

---@class MapargDict
---@field lhs string The {lhs} of the mapping.
---@field rhs string The {rhs} of the mapping as typed.
---@field silent number 1 for a |:map-silent| mapping, else 0.
---@field noremap number 1 if the {rhs} of the mapping is not remappable.
---@field expr number 1 for an expression mapping (|:map-<expr>|).
---@field buffer number 1 for a buffer local mapping (|:map-local|).
---@field mode string | "'n'" | "'v'" | "'x'" | "'s'" | "'o'" | "'!'" | "'i'" | "'l'" | "'c'" | "'t'" | "''" | "' '" | "'!'"  " " Normal, Visual and Operator-pending, "!" Insert and Commandline mode (|mapmode-ic|)
---@field sid number The script local ID, used for <sid> mappings (|<SID>|).

---@class Utils
local M = {}

---check if cursor is at a certain position
---@param line number
---@param col number
---@return boolean
M.is_cursor_at_position = function(line, col)
    local cursor = api.nvim_win_get_cursor(0)

    return line == cursor[1] - 1 and col == cursor[2]
end

---registers a command!
---@param command string
---@param fn_string string
M.register_command = function(command, fn_string)
    api.nvim_command('command! ' .. command .. ' ' .. fn_string)
end

---escape a string
---@param str string
M.replace = function(str)
    return api.nvim_replace_termcodes(str, true, true, true)
end

---map a key in mode
---@param mode string | "'n'" | "'v'" | "'x'" | "'s'" | "'o'" | "'!'" | "'i'" | "'l'" | "'c'" | "'t'" | "''"
---@param lhs string
---@param rhs string
---@param opts? {silent: boolean, expr: boolean}
M.map = function(mode, lhs, rhs, opts)
    local options = {noremap = true}
    if opts then options = vim.tbl_extend('force', options, opts) end
    api.nvim_set_keymap(mode, lhs, rhs, options)
end

---unmap a key in mode
---@param mode string | "'n'" | "'v'" | "'x'" | "'s'" | "'o'" | "'!'" | "'i'" | "'l'" | "'c'" | "'t'" | "''"
---@param lhs string
M.unmap = function(mode, lhs) api.nvim_del_keymap(mode, lhs) end

--[[ ---get mapargs dict for a binding
---@param mapping string
---@param mode string | "'n'" | "'v'" | "'x'" | "'s'" | "'o'" | "'!'" | "'i'" | "'l'" | "'c'" | "'t'" | "''"
---@return MapargDict
M.get_mapargs = function(mapping, mode) return
    vim.fn.maparg(mapping, mode, 0, 1) end

---determine if a maparg is valid by its dict
---@param dict MapargDict
---@return boolean
M.is_valid_mapping = function(dict) return next(dict) and dict.rhs ~= '' end ]]

---get the global rhs for a lhs
---@param lhs string
---@param mode string | "'n'" | "'v'" | "'x'" | "'s'" | "'o'" | "'!'" | "'i'" | "'l'" | "'c'" | "'t'" | "''"
---@return string
M.get_rhs = function(lhs, mode)
    local rhs = ''

    for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do
        if mapping.lhs:match(lhs) then
            if mapping.rhs ~= '' then rhs = mapping.rhs end
            break
        end
    end

    return rhs
end

return M
