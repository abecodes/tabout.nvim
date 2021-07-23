local M = {}

M.name = 'tabout.nvim'

--- @class TaboutOptions
local defaults = {
    tabkey = '<Tab>', -- key to trigger tabout
    act_as_tab = true, -- shift content if tab out is not possible
    completion = true, -- if the tabkey is used in a completion pum
    tabouts = {
        {open = "'", close = "'"}, {open = '"', close = '"'},
        {open = '`', close = '`'}, {open = '(', close = ')'},
        {open = '[', close = ']'}, {open = '{', close = '}'}
    },
    ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
    exclude = {} -- tabout will ignore these filetypes
}

--- @type TaboutOptions
M.options = {}
M.tabouts = {}
M.debug = false

M.setup = function(options)
    M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
    for _, combo in pairs(M.options.tabouts) do
        M.tabouts[combo.open] = combo.close
    end
end

return M
