local api = vim.api
local logger = require('tabout.logger')
local utils = require('tabout.utils')
local config = require('tabout.config')
local tab = require('tabout.tab')

local M = {}
local enabled = false

--[[ If e.g. a smarttabs expr is used for the completion pmu it is stored here ]]
local completion_binding = ''
local completion_back_binding = ''

local enable = function()
    if config.options.tabkey ~= '' then
        completion_binding = utils.get_rhs(config.options.tabkey, 'i')
        if config.options.completion and completion_binding ~= '' then
            if config.debug then
                logger.log('setting: ' .. config.options.tabkey ..
                               ':!pumvisible() ? "<Cmd>Tabout<Cr>" : ' ..
                               completion_binding)
            end
            utils.map('i', config.options.tabkey,
                      '!pumvisible() ? "<Cmd>Tabout<Cr>" : ' ..
                          completion_binding, {silent = true, expr = true})
        else
            utils.map('i', config.options.tabkey, "<Cmd>Tabout<Cr>",
                      {silent = true})
        end
    end

    if config.options.backwards_tabkey ~= '' and config.options.enable_backwards then
        completion_back_binding = utils.get_rhs(config.options.backwards_tabkey,
                                                'i')
        if config.options.completion and completion_back_binding ~= '' then
            if config.debug then
                logger.log('setting: ' .. config.options.backwards_tabkey ..
                               ':!pumvisible() ? "<Cmd>TaboutBack<Cr>" : ' ..
                               completion_back_binding)
            end
            utils.map('i', config.options.backwards_tabkey,
                      '!pumvisible() ? "<Cmd>TaboutBack<Cr>" : ' ..
                          completion_back_binding, {expr = true})
        else
            utils.map('i', config.options.backwards_tabkey,
                      "<Cmd>TaboutBack<Cr>", {silent = true})
        end
    end

    enabled = true
    if config.debug then logger.log("enabled") end
end

local disable = function()
    if config.debug then logger.log("unsetting: " .. config.options.tabkey) end

    if config.options.tabkey ~= '' then
        utils.unmap('i', config.options.tabkey)
        if config.options.completion and completion_binding ~= '' then
            if config.debug then
                logger.log("resetting: " .. config.options.tabkey .. ": " ..
                               completion_binding)
            end
            utils.map('i', config.options.tabkey, completion_binding, {
                silent = true,
                expr = string.sub(completion_binding, 1, 2) == 'v:'
            })
        end
    end

    if config.options.backwards_tabkey ~= '' and config.options.enable_backwards then
        if config.debug then
            logger.log("unsetting: " .. config.options.backwards_tabkey)
        end
        utils.unmap('i', config.options.backwards_tabkey)
        if config.options.completion and completion_back_binding ~= '' then
            if config.debug then
                logger.log("resetting: " .. config.options.backwards_tabkey ..
                               ": " .. completion_back_binding)
            end
            utils.map('i', config.options.backwards_tabkey,
                      completion_back_binding, {
                silent = true,
                expr = string.sub(completion_back_binding, 1, 2) == 'v:'
            })
        end
    end

    enabled = false
    if config.debug then logger.log("disabled") end
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
        logger.warn('nvim-treesitter is missing')
        return
    end

    config.setup(options)

    utils.register_command('Tabout', 'lua require"tabout".tabout()')
    utils.register_command('TaboutMulti', 'lua require"tabout".taboutMulti()')
    utils.register_command('TaboutBack', 'lua require"tabout".taboutBack()')
    utils.register_command('TaboutBackMulti',
                           'lua require"tabout".taboutBackMulti()')
    utils.register_command('TaboutToggle', 'lua require"tabout".toggle()')

    utils.map('i', '<Plug>Tabout', '<Cmd>lua require"tabout".tabout()<Cr>')
    utils.map('i', '<Plug>TaboutMulti',
              '<Cmd>lua require"tabout".taboutMulti()<Cr>')
    utils.map('i', '<Plug>TaboutBack',
              '<Cmd>lua require"tabout".taboutBack()<Cr>')
    utils.map('i', '<Plug>TaboutBackMulti',
              '<Cmd>lua require"tabout".taboutBackMulti()<Cr>')

    M.toggle()
end

M.toggle = function()
    if enabled then
        disable()
    else
        enable()
    end
end

M.tabout = function() tab.tabout('forward', enabled) end
M.taboutMulti = function() tab.tabout('forward', enabled, true) end
M.taboutBack = function() tab.tabout('backward', enabled) end
M.taboutBackMulti = function() tab.tabout('backward', enabled, true) end

return M
