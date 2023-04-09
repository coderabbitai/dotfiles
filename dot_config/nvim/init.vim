set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath

" Note: Plugins are listed in ~/.vimrc
source ~/.vimrc

lua << EOF

-- update remote plugins to make wilder work
local UpdatePlugs = vim.api.nvim_create_augroup("UpdateRemotePlugs", {})
vim.api.nvim_create_autocmd({ "VimEnter", "VimLeave" }, {
  pattern = "*",
  group = UpdatePlugs,
  command = "runtime! plugin/rplugin.vim",
})
vim.api.nvim_create_autocmd({ "VimEnter", "VimLeave" }, {
  pattern = "*",
  group = UpdatePlugs,
  command = "silent! UpdateRemotePlugins",
})

require'nvim-treesitter.configs'.setup {
  ensure_installed = { "go", "rust", "c", "python", "lua", "javascript", "bash", "cpp", "css", "dockerfile", "gomod", "gowork", "graphql", "hcl", "http", "html", "java", "json", "proto", "regex", "rego", "toml", "tsx", "typescript", "vim", "yaml", "make"},
  sync_install = false,
  highlight = {
    enable = true,
    disable = {"yaml"},
  },
  indent = {
    enable = true,
  }
}

require('telescope').load_extension('fzf')

require('bufferline').setup {
    options = {
        mode = "tabs",
        diagnostics = "coc"
    }
}


vim.notify = require("notify")
require("telescope").load_extension("notify")
local config = {
        background_colour = "Normal",
        fps = 30,
        icons = {
          DEBUG = "",
          ERROR = "",
          INFO = "",
          TRACE = "✎",
          WARN = ""
        },
        level = "info",
        minimum_width = 50,
        render = "default",
        stages = "fade_in_slide_out",
        timeout = 1000,
        top_down = false
      }
vim.notify.setup(config)

local coc_status_record = {}

function coc_status_notify(msg, level)
  local notify_opts = { title = "LSP Status", timeout = 500, hide_from_history = true, on_close = reset_coc_status_record }
  -- if coc_status_record is not {} then add it to notify_opts to key called "replace"
  if coc_status_record ~= {} then
    notify_opts["replace"] = coc_status_record.id
  end
  coc_status_record = vim.notify(msg, level, notify_opts)
end

function reset_coc_status_record(window)
  coc_status_record = {}
end

local coc_diag_record = {}

function coc_diag_notify(msg, level)
  local notify_opts = { title = "LSP Diagnostics", timeout = 500, on_close = reset_coc_diag_record }
  -- if coc_diag_record is not {} then add it to notify_opts to key called "replace"
  if coc_diag_record ~= {} then
    notify_opts["replace"] = coc_diag_record.id
  end
  coc_diag_record = vim.notify(msg, level, notify_opts)
end

function reset_coc_diag_record(window)
  coc_diag_record = {}
end

function notify(title, msg, level)
  local notify_opts = { title = title, timeout = 500 }
  vim.notify(msg, level, notify_opts)
end

function notify_output(command, opts)
  local output = ""
  local notification
  local notify = function(msg, level, time)
    local notify_opts = vim.tbl_extend(
      "keep",
      opts or {},
      { title = table.concat(command, " "), timeout = time, replace = notification }
    )
    notification = vim.notify(msg, level, notify_opts)
  end
  local on_data = function(_, data)
    output = output .. table.concat(data, "\n")
    -- remove all lines from output except the last 20 and save those to output
    local lines = vim.split(output, "\n")
    local num_lines = vim.fn.len(lines)
    if num_lines > 20 then
      local start_idx = num_lines - 20 + 1
      local end_idx = num_lines
      output = table.concat(lines, "\n", start_idx, end_idx)
    end
    notify(output, "info", false)
  end
  vim.fn.jobstart(command, {
    on_stdout = on_data,
    on_stderr = on_data,
    on_exit = function(_, code)
      if #output == 0 then
        notify("No output of command, exit code: " .. code, "warn", 1000)
      elseif code ~= 0 then
        notify(output, "error", 1000)
      else
        notify(output, "info", 1000)
      end
    end,
  })
end

require"octo".setup()

--[[if vim.env.OPENAI_API_KEY == nil then
  notify("ChatGPT", "OPENAI_API_KEY is not set, disabling", "warn")
else
  welcome_message = [[Welcome to ChatGPT!
    
    Available keybindings are:
    <C-c> to close chat window.
    <C-u> scroll up chat window.
    <C-d> scroll down chat window.
    <C-y> to copy/yank last answer.
    <C-o> Toggle settings window.
    <C-n> Start new session.
    <Tab> Cycle over windows.
    <C-i> [Edit Window] use response as input.

    In the sessions window:
    <Space> to select session.
    r to rename session.
    d to delete session.]]
--[[

  require("chatgpt").setup({
    welcome_message = welcome_message,
  })
end
--]]


EOF

autocmd FileType octo inoremap<buffer><silent> @ @<C-x><C-o>
autocmd FileType octo inoremap<buffer><silent> # #<C-x><C-o>

function! s:DiagnosticNotify() abort
  let l:info = get(b:, 'coc_diagnostic_info', {})
  if empty(l:info) | return '' | endif
  let l:msgs = []
  let l:level = 'info'
   if get(l:info, 'warning', 0)
    let l:level = 'warn'
  endif
  if get(l:info, 'error', 0)
    let l:level = 'error'
  endif
 
  if get(l:info, 'error', 0)
    call add(l:msgs, ' Errors: ' . l:info['error'])
  endif
  if get(l:info, 'warning', 0)
    call add(l:msgs, ' Warnings: ' . l:info['warning'])
  endif
  if get(l:info, 'information', 0)
    call add(l:msgs, ' Infos: ' . l:info['information'])
  endif
  if get(l:info, 'hint', 0)
    call add(l:msgs, ' Hints: ' . l:info['hint'])
  endif
  let l:msg = join(l:msgs, "\n")
  if empty(l:msg) | let l:msg = ' All OK' | endif
  call v:lua.coc_diag_notify(l:msg, l:level)
endfunction

function! s:StatusNotify() abort
  let l:status = get(g:, 'coc_status', '')
  let l:level = 'info'
  if empty(l:status) | return '' | endif
  call v:lua.coc_status_notify(l:status, l:level)
endfunction

function! s:InitCoc() abort
  " load overrides
  runtime! autoload/coc/ui.vim
endfunction

" notifications
autocmd User CocNvimInit call s:InitCoc()
autocmd User CocDiagnosticChange call s:DiagnosticNotify()
autocmd User CocStatusChange call s:StatusNotify()

command CocRename call CocActionAsync('rename', function('NotifyCocResponse'))

function! NotifyCocResponse(error, response) abort
  " print the values of error and response if they exist
  let l:msg = ''
  let l:level = 'info'
  if a:error
    let l:level = 'error'
    let l:msg = 'Error: '.a:error.'\nResponse: '.a:response
  endif
  if l:msg == ''
    let l:msg = ' Done!'
  endif
  call v:lua.notify('LSP Response', l:msg, l:level)
endfunction


command! -complete=shellcmd -nargs=+ Sh call s:RunSh(<q-args>)
function! s:RunSh(cmdline)
  echo a:cmdline
  let expanded_cmdline = a:cmdline
  let cmd = []
  for part in split(a:cmdline, ' ')
     if part[0] =~ '\v[%#<]'
        let part = fnameescape(expand(part))
     endif
     call add(cmd, part)
  endfor
  call v:lua.notify_output(cmd)
endfunction

" Tree sitter based folding
"set foldmethod=expr
"set foldexpr=nvim_treesitter#foldexpr()
