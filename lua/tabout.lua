local api = vim.api
local logger = require('tabout.logger')
local utils = require('tabout.utils')
local config = require('tabout.config')
local tab = require('tabout.tab')

local M = {}
local enabled = false

--[[ If e.g. a smarttabs expr is used for the completion pmu it is stored here ]]
local completion_binding = ''
local completion_binding_back = ''

local enable = function()
    completion_binding = vim.fn.maparg(config.options.tabkey, 'i')
    completion_binding_back = vim.fn
                                  .maparg(config.options.backwards_tabkey, 'i')

    if config.options.completion and completion_binding then
        if config.debug then
            logger.log('setting: ' .. config.options.tabkey ..
                           ':!pumvisible() ? "<Cmd>Tabout<Cr>" : ' ..
                           completion_binding)
        end
        utils.map('i', config.options.tabkey,
                  '!pumvisible() ? "<Cmd>Tabout<Cr>" : ' .. completion_binding,
                  {silent = true, expr = true})
    else
        utils.map('i', config.options.tabkey, "<Cmd>Tabout<Cr>", {silent = true})
    end

    if config.options.completion and completion_binding_back then
        --[[ print(completion_binding_back, #completion_binding_back,
              type(completion_binding_back)) ]]
        if config.debug then
            logger.log('setting: ' .. config.options.backwards_tabkey ..
                           ':!pumvisible() ? "<Cmd>TaboutBack<Cr>" : ' ..
                           completion_binding_back)
        end
        utils.map('i', config.options.backwards_tabkey,
                  '!pumvisible() ? "<Cmd>TaboutBack<Cr>" : ' ..
                      completion_binding_back, {expr = true})
    else
        utils.map('i', config.options.backwards_tabkey, "<Cmd>TaboutBack<Cr>",
                  {silent = true})
    end

    enabled = true
    logger.log("enabled")
end

local disable = function()
    if config.debug then logger.log("unsetting: " .. config.options.tabkey) end
    utils.unmap('i', config.options.tabkey)
    if config.debug then
        logger.log("unsetting: " .. config.options.backwards_tabkey)
    end
    utils.unmap('i', config.options.backwards_tabkey)

    if config.options.completion and completion_binding then
        if config.debug then
            logger.log("resetting: " .. config.options.tabkey .. ": " ..
                           completion_binding)
        end
        utils.map('i', config.options.tabkey, completion_binding, {
            silent = true,
            expr = string.sub(completion_binding, 1, 2) == 'v:'
        })
    end
    if config.options.completion and completion_binding_back then
        if config.debug then
            logger.log(
                "resetting: " .. config.options.backwards_tabkey .. ": " ..
                    completion_binding_back)
        end
        utils.map('i', config.options.backwards_tabkey, completion_binding_back,
                  {
            silent = true,
            expr = string.sub(completion_binding_back, 1, 2) == 'v:'
        })
    end

    enabled = false
    logger.log("disabled")
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

