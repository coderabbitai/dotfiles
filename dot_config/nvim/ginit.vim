if has("linux")
  if exists(':GuiTabline')
      GuiTabline 0
  endif

  if exists(':GuiAdaptiveColor')
      GuiAdaptiveColor 1
  endif

  if exists(':GuiPopupmenu')
      GuiPopupmenu 0
  endif

  if exists(':GuiScrollBar')
      GuiScrollBar 1
  endif

  if exists(':GuiRenderLigatures')
      GuiRenderLigatures 1
  endif

  if exists(':GuiAdaptiveStyle')
      GuiAdaptiveStyle Fusion
  endif

  " Right Click Context Menu (Copy-Cut-Paste)
  nnoremap <silent><RightMouse> :call GuiShowContextMenu()<CR>
  inoremap <silent><RightMouse> <Esc>:call GuiShowContextMenu()<CR>
  xnoremap <silent><RightMouse> :call GuiShowContextMenu()<CR>gv
  snoremap <silent><RightMouse> <C-G>:call GuiShowContextMenu()<CR>gv
endif
