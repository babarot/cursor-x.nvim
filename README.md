cursor-x.nvim
=============

<img src="https://user-images.githubusercontent.com/4442708/224540901-dd293581-d323-4997-8f41-fd6f4fe6ef0f.gif" width="400">

Automatically highlight the cursorline and cusorcolumn after the elapse of certain milliseconds.

## Quick start

#### With [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'b4b4r07/cursor-x.nvim',
  lazy = true,
  event = { 'BufRead' },
  config = function()
    require('cursor-x').setup({
      interval = 3000, -- 3s
      filetype_exclude = { 'neo-tree', 'yaml' },
    })
  end,
}
```

## Configuration

```lua
{
  interval = 3000,
  always_cursorline = true,
  -- example: if following original option setting
  -- always_cursorline = vim.opt.cursorline:get(),
  filetype_exclude = {'dirvish', 'fugitive'},
  buftype_exclude = {},
}
```

## Functions

#### `require('cursor-x').enable()`

Globally enable highlighing.

#### `require('cursor-x').disable()`

Globally disable highlighing.

## Thanks

[auto-cursorline.nvim](https://github.com/delphinus/auto-cursorline.nvim)
