local api = vim.api

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

return M
