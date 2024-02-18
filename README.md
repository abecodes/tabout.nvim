# 🦿 tabout.nvim

Supercharge your workflow and start tabbing out from parentheses, quotes, and similar contexts today.

<p>&nbsp;</p>

<p align="center">
  <img alt="intro" width="480" height="233" src="./assets/intro.gif">
</p>

<p>&nbsp;</p>

## 💡 examples

| Before | Key | After | Setting |
| --- | --- | --- | --- |
| `{ \| }` | `<Tab>` | `{} \| ` | - |
| `{ \|"string" }` | `<Tab>` | `{ "string"\| } ` | `ignore_beginning = true` |
| `{ \|"string" }` | `<Tab>` | `{ ....\|"string"}` | `ignore_beginning = false, act_as_tab = true,` |
| `{ "string"\| }` | `<S-Tab>` | `{ \|"string" } ` | - |
| `\|#[macro_use]` | `<Tab>` | `#[macro_use]\| ` | `tabouts = {{open = '#', close = ']'}}` |

<p>&nbsp;</p>

## 📦 requirements

- [nvim](https://neovim.io/) >= 0.5
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
<p>&nbsp;</p>

## 💾 installation

### [packer](https://github.com/wbthomason/packer.nvim)

```lua
-- Lua
use {
  'abecodes/tabout.nvim',
  config = function()
    require('tabout').setup {
    tabkey = '<Tab>', -- key to trigger tabout, set to an empty string to disable
    backwards_tabkey = '<S-Tab>', -- key to trigger backwards tabout, set to an empty string to disable
    act_as_tab = true, -- shift content if tab out is not possible
    act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
    default_tab = '<C-t>', -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
    default_shift_tab = '<C-d>', -- reverse shift default action,
    enable_backwards = true, -- well ...
    completion = true, -- if the tabkey is used in a completion pum
    tabouts = {
      {open = "'", close = "'"},
      {open = '"', close = '"'},
      {open = '`', close = '`'},
      {open = '(', close = ')'},
      {open = '[', close = ']'},
      {open = '{', close = '}'}
    },
    ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
    exclude = {} -- tabout will ignore these filetypes
}
  end,
	wants = {'nvim-treesitter'}, -- or require if not used so far
	after = {'nvim-cmp'} -- if a completion plugin is using tabs load it before
}
```
### [lazyvim](https://www.lazyvim.org/)

```lua
-- Lua
return {
  {
    'abecodes/tabout.nvim',
    lazy = false,
    config = function()
      require('tabout').setup {
        tabkey = '<Tab>', -- key to trigger tabout, set to an empty string to disable
        backwards_tabkey = '<S-Tab>', -- key to trigger backwards tabout, set to an empty string to disable
        act_as_tab = true, -- shift content if tab out is not possible
        act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
        default_tab = '<C-t>', -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
        default_shift_tab = '<C-d>', -- reverse shift default action,
        enable_backwards = true, -- well ...
        completion = false, -- if the tabkey is used in a completion pum
        tabouts = {
          { open = "'", close = "'" },
          { open = '"', close = '"' },
          { open = '`', close = '`' },
          { open = '(', close = ')' },
          { open = '[', close = ']' },
          { open = '{', close = '}' }
        },
        ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
        exclude = {} -- tabout will ignore these filetypes
      }
    end,
    requires = {
      "nvim-treesitter/nvim-treesitter",
      "L3MON4D3/LuaSnip",
      "hrsh7th/nvim-cmp"
    },
    opt = true,  -- Set this to true if the plugin is optional
    event = 'InsertCharPre', -- Set the event to 'InsertCharPre' for better compatibility
    priority = 1000,
  },
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      -- Disable default tab keybinding in LuaSnip
      return {}
    end,
  },
}

```

If you use another plugin manager just make sure `tabout.nvim` is loaded after `nvim-treesitter` and any completion that already uses your _tabkey_.


<p>&nbsp;</p>

## 🛠️ options

### tabkey

Set the key you want to use to trigger tabout.

```lua
-- default
tabkey = '<Tab>'
```

### backwards_tabkey

Set the key you want to use to trigger tabout backwards.

```lua
-- default
backwards_tabkey = '<S-Tab>'
```

### act_as_tab

If a tab out is not possible shift the content.

```lua
-- default
act_as_tab = true
```

### act_as_shift_tab

If a backwards tab out is not possible reverse shift the content. (Depends on keyboard/terminal if it will work)

```lua
-- default
act_as_shift_tab = false
```

### default_tab

If `act_as_tab` is set to true, a tab out is not possible, and the cursor is at the beginnig of a line, this keysignals are sent in `insert` mode.

```lua
-- default
default_tab = '<C-t>'
```

### default_shift_tab

If `act_as_shift_tab` is set to true and a tab out is not possible, this keysignals are sent in `insert` mode.

```lua
-- default
default_shift_tab = '<C-d>'
```

### enable_backwards

Disable if you just want to move forward

```lua
-- default
enable_backwards = true
```

### completion

> Consider using the [Plug API](#🤖-plug-api) and setting this to false

If you use a completion _pum_ that also uses the tab key for a smart scroll function. Setting this to true will disable tab out when the _pum_ is open and execute the smart scroll function instead.

[See here](#more-complex-keybindings) how to ingegrate `tabout.vim` into more complex completions with snippets.

```lua
-- default
completion = true
```

### tabouts

Here you can add more symbols you want to tab out from.

**open an close can only contain one character for now**

```lua
-- default
tabouts = {
  {open = "'", close = "'"},
  {open = '"', close = '"'},
  {open = '`', close = '`'},
  {open = '(', close = ')'},
  {open = '[', close = ']'},
  {open = '{', close = '}'}
}
```

### ignore_beginning

If set to true you can also tab out from the beginning of a string, object property, etc.

```lua
-- default
ignore_beginning = true
```

### more complex keybindings

You can set `tabkey` and `backwards_tabkey` to empty strings and define more complex keybindings instead.

For example, to make `<Tab>` and `<S-Tab>` work with [nvim-compe](https://github.com/hrsh7th/nvim-compe), [vim-vsnip](https://github.com/hrsh7th/vim-vsnip) and this plugin:

```lua
require("tabout").setup({
  tabkey = "",
  backwards_tabkey = "",
})

local function replace_keycodes(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function _G.tab_binding()
  if vim.fn.pumvisible() ~= 0 then
    return replace_keycodes("<C-n>")
  elseif vim.fn["vsnip#available"](1) ~= 0 then
    return replace_keycodes("<Plug>(vsnip-expand-or-jump)")
  else
    return replace_keycodes("<Plug>(Tabout)")
  end
end

function _G.s_tab_binding()
  if vim.fn.pumvisible() ~= 0 then
    return replace_keycodes("<C-p>")
  elseif vim.fn["vsnip#jumpable"](-1) ~= 0 then
    return replace_keycodes("<Plug>(vsnip-jump-prev)")
  else
    return replace_keycodes("<Plug>(TaboutBack)")
  end
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_binding()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_binding()", {expr = true})
```

Note that some other plugins that also use `<Tab>` and `<S-Tab>` might provide already handlers to avoid clashes with `tabout.nvim`.

For example [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) mappings can be created using a function that accepts a callback. When the fallback is called `tabout.nvim` is working out of the box and there is no need for special configurations.

The example below shows `nvim-cmp` with `luasnip` mappings using the fallback function:

```lua
['<Tab>'] = function(fallback)
    if cmp.visible() then
      cmp.select_next_item()
    elseif luasnip.expand_or_jumpable() then
      vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-expand-or-jump', true, true, true), '')
    else
      fallback()
    end
  end,
  ['<S-Tab>'] = function(fallback)
    if cmp.visible() then
      cmp.select_prev_item()
    elseif luasnip.jumpable(-1) then
      vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-jump-prev', true, true, true), '')
    else
      fallback()
    end
  end,
```

To make `<Tab>` and `<S-Tab>` work with `vim-vsnip`:

```lua
["<Tab>"] = function(fallback)
  if cmp.visible() then
    -- cmp.select_next_item()
    cmp.confirm(
      {
        behavior = cmp.ConfirmBehavior.Insert,
        select = true
      }
    )
  elseif vim.fn["vsnip#available"](1) ~= 0 then
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>(vsnip-expand-or-jump)", true, true, true), "")
  else
    fallback()
  end
end,
["<S-Tab>"] = function(fallback)
  if cmp.visible() then
    cmp.select_prev_item()
  elseif vim.fn["vsnip#available"](1) ~= 0 then
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>(vsnip-jump-prev)", true, true, true), "")
  else
    fallback()
  end
end,
```

See [here](https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings) for more `nvim-cmp` examples.

<p>&nbsp;</p>

## 🤖 plug api

| Mode | plug                      | action                                               |
| ---- | ------------------------- | ---------------------------------------------------- |
| i    | `<Plug>(Tabout)`          | tabout of current context (current line)             |
| i    | `<Plug>(TaboutMulti)`     | tabout of current context (multiple lines)           |
| i    | `<Plug>(TaboutBack)`      | tabout backwards of current context (current line)   |
| i    | `<Plug>(TaboutBackMulti)` | tabout backwards of current context (multiple lines) |

### multiline tabout

```lua
-- A multiline tabout setup could look like this
vim.api.nvim_set_keymap('i', '<A-x>', "<Plug>(TaboutMulti)", {silent = true})
vim.api.nvim_set_keymap('i', '<A-z>', "<Plug>(TaboutBackMulti)", {silent = true})
```

<p>&nbsp;</p>

## 📋 commands

| command      | triggers                                                    |
| ------------ | ----------------------------------------------------------- |
| Tabout       | 🚨 DEPRECATED tries to tab out of current context           |
| TaboutBack   | 🚨 DEPRECATED tries to tab out backwards of current context |
| TaboutToggle | (de)activates the plugin                                    |

<p>&nbsp;</p>

## ⚠️ exceptions

`tabout.nvim` only works with [nvim-treesitter's supported filetypes](https://github.com/nvim-treesitter/nvim-treesitter#supported-languages).

<p>&nbsp;</p>

## ✅ todo

- [ ] tabout in blockcomment strings
- [x] allow multi line tabout
- [ ] support multi character tabouts
