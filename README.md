# fixquick.nvim

Parse build/lint output into Neovim's quickfix list.

## Installation

### lazy.nvim

```lua
{ "mklinovsky/fixquick.nvim" }
```

To override defaults:

```lua
{
  "mklinovsky/fixquick.nvim",
  config = function()
    require("fixquick").setup({
      commands = true, -- Create user commands (default: true)
      open_qf = true,  -- Auto-open quickfix window (default: true)
    })
  end,
}
```

## Commands

| Command | Description |
|---|---|
| `:FixQuick` | Parse system clipboard and populate quickfix |
| `:FixQuickBuffer` | Parse current buffer and populate quickfix |
| `:FixQuickRun <cmd>` | Run a shell command, parse output into quickfix |

### Examples

```vim
" Copy eslint output to clipboard, then:
:FixQuick

" Run tsc:
:FixQuickRun tsc --noEmit
```

## Lua API

```lua
local fixquick = require("fixquick")

-- Parse text and populate quickfix
fixquick.parse_and_populate(text, { title = "my errors" })

-- Run a command asynchronously
fixquick.run("tsc --noEmit")

-- Just parse (returns list of { path, line, col, message })
local parser = require("fixquick.parser")
local results = parser.parse(text)
```


## Supported formats

- **eslint** - File path on its own line, indented `line:col  severity  message` below
- **tsc / gcc / generic** - `path:line:col` on a single line (fallback)
