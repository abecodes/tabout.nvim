local api = vim.api
local log = require('tabout.logger')
local utils = require('tabout.utils')
local config = require('tabout.config')
local tab = require('tabout.tab')

local M = {}
local enabled = false

--[[ If e.g. a smarttabs expr is used for the completion pmu it is stored here ]]
local completion_binding = ''
local completion_binding_back = ''

local enable = function()
    if config.options.completion then
        completion_binding = vim.fn.maparg(utils.replace(config.options.tabkey),
                                           'i')
        completion_binding_back = vim.fn.maparg(config.options.backwards_tabkey,
                                                'i')

        utils.map('i', utils.replace(config.options.tabkey),
                  '!pumvisible() ? "<Cmd>Tabout<Cr>" : ' .. completion_binding,
                  {silent = true, expr = true})
        utils.map('i', config.options.backwards_tabkey,
                  '!pumvisible() ? "<Cmd>TaboutBack<Cr>" : ' ..
                      completion_binding_back, {expr = true})
    else
        utils.map('i', utils.replace(config.options.tabkey), "<Cmd>Tabout<Cr>",
                  {silent = true})
        utils.map('i', utils.replace(config.options.backwards_tabkey),
                  "<Cmd>TaboutBack<Cr>", {silent = true})
    end

    enabled = true
    log.log("enabled")
end

local disable = function()
    if config.options.completion and completion_binding then
        utils.unmap('i', utils.replace(config.options.tabkey))
        utils.unmap('i', utils.replace(config.options.backwards_tabkey))

        utils.map('i', utils.replace(config.options.tabkey), completion_binding,
                  {
            silent = true,
            expr = string.sub(completion_binding, 1, 2) == 'v:'
        })
        utils.map('i', utils.replace(config.options.backwards_tabkey),
                  completion_binding_back, {
            silent = true,
            expr = string.sub(completion_binding_back, 1, 2) == 'v:'
        })
    else
        utils.unmap('i', utils.replace(config.options.tabkey))
        utils.unmap('i', utils.replace(config.options.backwards_tabkey))
    end

    enabled = false
    log.log("disabled")
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
        return
    end

    config.setup(options)

    utils.register_command('Tabout', 'lua require"tabout".tabout()')
    utils.register_command('TaboutBack', 'lua require"tabout".taboutBack()')
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

M.tabout = function() tab.forward(enabled) end
M.taboutBack = function() tab.backward(enabled) end

return M

