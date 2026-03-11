# termpop

A Neovim plugin for managing floating terminal windows with a sleek tabbed interface.

<img width="1930" height="1092" alt="Screenshot From 2026-03-10 18-11-11" src="https://github.com/user-attachments/assets/ebf13fc5-e016-4cdc-8b24-0fe0f4a46f75" />


https://github.com/user-attachments/assets/4b56bd31-a510-4f34-a422-ad1506709182


## Features

- Multiple terminal buffers in floating windows
- Tab bar showing all active terminals
- Easy navigation between terminals
- Customizable keybindings
- Configurable window size and borders
- Automatic terminal cleanup
- Send commands to terminals programmatically

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "govind-varadar/termpop",
  branch = "mother", -- master? main? eff it, mother branch it is
  dependencies = "nvzone/volt",
  opts = {
    border = true,
    toggle_keymap = { {"n", "t"}, "<F12>"},
    new_term_keymap = { {"n", "t"}, "<F9>", function()
      require("termpop").add_term({ name = "bash" })
    end},
    prev_term_keymap = { {"n", "t"}, "<F10>"},
    next_term_keymap = { {"n", "t"}, "<F11>"},
    size = { h = 100, w = 85 },
    name = "bash",
    cmd = { "bash" },
  },
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "govind-varadar/termpop",
  branch = "mother",
  requires = { "nvzone/volt" },
  config = function()
    require("termpop").setup({
      border = true,
      toggle_keymap = { {"n", "t"}, "<F12>"},
      new_term_keymap = { {"n", "t"}, "<F9>", function()
        require("termpop").add_term({ name = "bash" })
      end},
      prev_term_keymap = { {"n", "t"}, "<F10>"},
      next_term_keymap = { {"n", "t"}, "<F11>"},
      size = { h = 100, w = 85 },
      name = "bash",
      cmd = { "bash" },
    })
  end
}
```

## Configuration

```lua
require("termpop").setup({
  -- Enable or disable window borders
  border = true,

  -- Optional log file for debugging
  logfile = os.getenv("HOME") .. "/.cache/termpop.log",

  -- Keymap to toggle the terminal popup (modes, key)
  toggle_keymap = { {"n", "t"}, "<F12>" },

  -- Keymap to create a new terminal (modes, key, optional function)
  new_term_keymap = { {"n", "t"}, "<F9>", function()
    require("termpop").add_term({ name = "bash" })
  end},

  -- Keymap to switch to previous terminal
  prev_term_keymap = { {"n", "t"}, "<F10>" },

  -- Keymap to switch to next terminal
  next_term_keymap = { {"n", "t"}, "<F11>" },

  -- Window size as percentage of editor dimensions
  size = {
    h = 100,  -- height percentage
    w = 85    -- width percentage
  },

  -- Default name for terminal tabs
  name = "bash",

  -- Default shell command
  cmd = { "bash" },
})
```

## Usage

### Basic Commands

The plugin provides several functions you can bind to keymaps or call directly:

- `require("termpop").toggle()` - Show/hide the terminal popup
- `require("termpop").add_term(opts)` - Create a new terminal
- `require("termpop").next_term()` - Switch to the next terminal
- `require("termpop").prev_term()` - Switch to the previous terminal

### Built-in Keybindings

When inside a terminal buffer:

- `<C-Del>` - Delete the current terminal buffer (normal and terminal mode)

### Creating Custom Terminals

You can create terminals with custom names and commands:

```lua
require("termpop").add_term({
  name = "Python",
  cmd = { "python3" }
})

-- Create a terminal for Claude Code
require("termpop").add_term({
  name = "Claude",
  cmd = { "claude" }
})

-- Create a terminal for Cursor Agent
require("termpop").add_term({
  name = "Cursor",
  cmd = { "cursor", "agent" }
})
```

### Sending Commands to Terminals

Send a command to the current terminal:

```lua
require("termpop").send_to_cur_terminal("echo 'Hello'\n")
```

Send a command to a specific terminal by name:

```lua
require("termpop").send_to_term("Python", "print('Hello')\n")
```

### Showing a Specific Terminal

Switch to a terminal by its buffer number:

```lua
require("termpop").show_term(buf_number)
```

### Advanced Usage: Send Filename to Terminal

Send the current file path to a specific terminal (useful for Claude Code and Cursor Agent):

```lua
local termpop = require("termpop")

-- Helper function to create terminal toggle
local function make_toggle(name, cmd)
  return function()
    local i, v = termpop.find_term(name)
    if v then
      termpop.show_term(v.buf)
    else
      termpop.add_term({ name = name, cmd = cmd })
    end
  end
end

local claude_toggle = make_toggle("claude", { "claude" })

-- Send current filename to terminal
local function sendfilename(term_name, toggle_func)
  local filename = vim.api.nvim_buf_get_name(0)
  toggle_func()
  termpop.send_to_term(term_name, "@" .. filename .. "\n")
end

-- Keymap to send filename to Claude Code
vim.keymap.set("n", "<leader>bf", function()
  sendfilename("claude", claude_toggle)
end, {desc = "send filename to claude code and toggle claude terminal"})
```

### Advanced Usage: Send Filename with Line Range

Send the current file path with a line range to a specific terminal (for visual selections):

```lua
-- Send filename with line range (for visual mode)
local function sendfilename_line(term_name, toggle_func)
  local filename = vim.api.nvim_buf_get_name(0)
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local arg = "@" .. filename .. ":" .. start_line .. "-" .. end_line .. "\n"
  toggle_func()
  termpop.send_to_term(term_name, arg)
end

-- Keymap to send filename with line range to Claude Code (visual mode)
vim.keymap.set("v", "<leader>bl", function()
  sendfilename_line("claude", claude_toggle)
end, {desc = "send filename and line number to claude and toggle claude terminal"})
```

## Example Setup

```lua
require("termpop").setup({
  toggle_keymap = { "n", "<C-\\>" },
  new_term_keymap = { "n", "<leader>tn" },
  next_term_keymap = { "t", "<C-PageDown>" },
  prev_term_keymap = { "t", "<C-PageUp>" },
  size = { h = 70, w = 90 },
  border = true,
  name = "Terminal"
})
```

## Dependencies

- [volt](https://github.com/nvzone/volt) - Required for the tab bar rendering


