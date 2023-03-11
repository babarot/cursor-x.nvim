augroup CursorX
  autocmd!
  autocmd WinEnter * setlocal cursorline
  autocmd WinLeave * setlocal nocursorline nocursorcolumn
  autocmd BufLeave,CursorMoved,CursorMovedI * lua require('cursor-x').appear(false)
  autocmd BufEnter,CursorHold,CursorHoldI   * lua require('cursor-x').appear(true)
augroup END
