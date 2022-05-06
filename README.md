# auto-cursorline.nvim

![demo](https://user-images.githubusercontent.com/1239245/56327655-4c169000-61b6-11e9-8cb8-23d3ca1773a7.gif)

Show / hide cursorline in connection with cursor moving.

## What's this?

This plugin manages the `'cursorline'` option to show only when you need.

NOTE: This plugin is for Neovim (>= 0.7.0) only.
NOTE: This is a Lua version of [vim-auto-cursorline][].

[vim-auto-cursorline]: https://github.com/delphinus/vim-auto-cursorline

## Install

In case, you use [packer.nvim][].

[packer.nvim]: https://github.com/wbthomason/packer.nvim

```lua
require("packer").startup(function()
  use {
    "delphinus/auto-cursorline.nvim",
    config = function()
      require("auto-cursorline").setup {}
    end,
  }
end)
```

For usage and other settings, see the [doc][].

[doc]: doc/auto-cursorline.txt
