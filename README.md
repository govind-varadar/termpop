# termpop

A Neovim plugin for managing floating terminal windows with a sleek tabbed interface.

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
  "termpop",
  dependencies = { "volt" },
  config = function()
    require("termpop").setup()
  end
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "termpop",
  requires = { "volt" },
  config = function()
    require("termpop").setup()
  end
}
```

## Configuration

```lua
require("termpop").setup({
  -- Keymap to toggle the terminal popup
  toggle_keymap = { "n", "<leader>tt" },

  -- Keymap to create a new terminal
  new_term_keymap = { "n", "<leader>tn" },

  -- Keymap to switch to next terminal
  next_term_keymap = { "t", "<C-]>" },

  -- Keymap to switch to previous terminal
  prev_term_keymap = { "t", "<C-[>" },

  -- Window size as percentage of editor dimensions
  size = {
    h = 80,  -- height percentage
    w = 80   -- width percentage
  },

  -- Enable or disable window borders
  border = true,

  -- Default name for terminal tabs
  name = "Term",

  -- Default shell command
  cmd = { vim.o.shell },

  -- Optional log file for debugging
  logfile = "/tmp/termpop.log"
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

- [volt](https://github.com/volt-nvim/volt) - Required for the tab bar rendering

## License

MIT
