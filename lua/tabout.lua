local api = vim.api
local log = require('tabout.logger')
local utils = require('tabout.utils')
local config = require('tabout.config')
local tab = require('tabout.tab')

local M = {}
local enabled = false

--[[ If e.g. a smarttabs expr is used for the completion pmu it is stored here ]]
local completion_binding = ''

local enable = function()
    if config.options.completion then
        completion_binding = vim.fn.maparg(utils.replace(config.options.tabkey),
                                           'i')

        utils.map('i', utils.replace(config.options.tabkey),
                  '!pumvisible() ? "<Cmd>Tabout<Cr>" : ' .. completion_binding,
                  {silent = true, expr = true})
    else
        utils.map('i', utils.replace(config.options.tabkey),
                  utils.replace('<Cmd>Tabout<Cr>'), {silent = true, expr = true})
    end

    enabled = true
end

local disable = function()
    if config.options.completion and completion_binding then
        utils.unmap('i', utils.replace(config.options.tabkey))

        utils.map('i', utils.replace(config.options.tabkey), completion_binding,
                  {
            silent = true,
            expr = string.sub(completion_binding, 1, 2) == 'v:'
        })
    else
        utils.unmap('i', utils.replace(config.options.tabkey))
    end

    enabled = false
end

M.valid_filetype = function()
    local win = vim.api.nvim_get_current_win()

    if not enabled or not vim.api.nvim_win_is_valid(win) then return false end
    local buf = vim.api.nvim_win_get_buf(win)
    local buftype = api.nvim_buf_get_option(buf, "buftype")
    if buftype ~= "" then return false end
    local filetype = api.nvim_buf_get_option(buf, "filetype")
    if vim.tbl_contains(config.options.exclude, filetype) then return false end

end

--- @param options TaboutOptions
M.setup = function(options)
    if not vim.fn.exists(':TSInstall') then
        log.warn('nvim-treesitter is missing')
        -- return
    end

    config.setup(options)

    utils.register_command('Tabout', 'lua require"tabout".tabout()')
    utils.register_command('TaboutToggle', 'lua require"tabout".toggle()')

    M.toggle()
end

M.toggle = function()
    if enabled then
        disable()
    else
        enable()
    end
end

M.tabout = function() tab(enabled) end

return M

