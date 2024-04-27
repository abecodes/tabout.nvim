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
        if config.options.completion and utils.str_is_empty(completion_binding) == false then
            logger.debug('setting: ' .. config.options.tabkey ..
                             ':!pumvisible() ? "<Plug>(Tabout)" : ' ..
                             completion_binding)
            api.nvim_set_keymap('i', config.options.tabkey,
                                '!pumvisible() ? "<Plug>(Tabout)" : ' ..
                                    completion_binding,
                                {silent = true, expr = true})
        else
            -- The () are needed to prevent characters from flashing up when multiple plugs are defined
            -- TODO: investigate why
            api.nvim_set_keymap('i', config.options.tabkey, "<Plug>(Tabout)",
                                {silent = true})
        end
    end

    if config.options.backwards_tabkey ~= '' and config.options.enable_backwards then
        completion_back_binding = utils.get_rhs(config.options.backwards_tabkey,
                                                'i')
        if config.options.completion and utils.str_is_empty(completion_back_binding) == false then
            logger.debug('setting: ' .. config.options.backwards_tabkey ..
                             ':!pumvisible() ? "<Plug>(TaboutBack)" : ' ..
                             completion_back_binding)
            api.nvim_set_keymap('i', config.options.backwards_tabkey,
                                '!pumvisible() ? "<Plug>(TaboutBack)" : ' ..
                                    completion_back_binding, {expr = true})
        else
            api.nvim_set_keymap('i', config.options.backwards_tabkey,
                                "<Plug>(TaboutBack)", {silent = true})
        end
    end

    enabled = true
    logger.debug("enabled")
end

local disable = function()
    logger.debug("unsetting: " .. config.options.tabkey)

    if config.options.tabkey ~= '' then
        utils.unmap('i', config.options.tabkey)
        if config.options.completion and utils.str_is_empty(completion_binding) == false then
            logger.debug("resetting: " .. config.options.tabkey .. ": " ..
                             completion_binding)
            -- a map over noremap since otherwise things like smarttabs with compe and vsnip wont work
            api.nvim_set_keymap('i', config.options.tabkey, completion_binding,
                                {
                silent = true,
                expr = string.sub(completion_binding, 1, 2) == 'v:'
            })
        end
    end

    if config.options.backwards_tabkey ~= '' and config.options.enable_backwards then
        logger.debug("unsetting: " .. config.options.backwards_tabkey)
        utils.unmap('i', config.options.backwards_tabkey)
        if config.options.completion and utils.str_is_empty(completion_back_binding) == false then
            logger.debug("resetting: " .. config.options.backwards_tabkey ..
                             ": " .. completion_back_binding)
            -- a map over noremap since otherwise things like smarttabs with compe and vsnip wont work
            api.nvim_set_keymap('i', config.options.backwards_tabkey,
                                completion_back_binding, {
                silent = true,
                expr = string.sub(completion_back_binding, 1, 2) == 'v:'
            })
        end
    end

    enabled = false
    logger.debug("disabled")
end

-- Checks if tabout is currently enabled (Tabout can be toggled on/off using the TaboutToggle command)
--- @return boolean enabled If tabout is currently enabled
M.is_enabled = function()
    return enabled
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
    config.setup(options)

    -- DEPRECATED: Remove after the end of 09/2021
    utils.register_command('Tabout',
                           'lua require"tabout.logger".warn(":Tabout will be deprecated soon, use < Plug >(Tabout) instead") require"tabout".tabout()')
    -- DEPRECATED: Remove after the end of 09/2021
    utils.register_command('TaboutBack',
                           'lua require"tabout.logger".warn(":TaboutBack will be deprecated soon, use < Plug >(TaboutBack) instead") require"tabout".taboutBack()')
    utils.register_command('TaboutToggle', 'lua require"tabout".toggle()')

    -- interfacing via plug api to get more flexibility
    utils.map('i', '<Plug>(Tabout)', '<Cmd>lua require("tabout").tabout()<CR>')
    utils.map('i', '<Plug>(TaboutMulti)',
              '<Cmd>lua require("tabout").taboutMulti()<CR>')
    utils.map('i', '<Plug>(TaboutBack)',
              '<Cmd>lua require("tabout").taboutBack()<CR>')
    utils.map('i', '<Plug>(TaboutBackMulti)',
              '<Cmd>lua require("tabout").taboutBackMulti()<CR>')

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
