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

require'nvim-web-devicons'.setup {
 color_icons = true;
 default = true;
 strict = true;
}

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
        diagnostics = "coc",
        buffer_close_icon = "󰅙",
        modified_icon = "",
        close_icon = "󰅙",
        left_trunc_marker = "",
        right_trunc_marker = "",
        offsets = {
          {filetype = "coc-explorer", text = "File Explorer", text_align = "center"},
          {filetype = "coctree", text = "Tree", text_align = "center"},
          {filetype = "Mundo", text = "Mundo", text_align = "center"},
          {filetype = "MundoDiff", text = "Mundo", text_align = "center"}
        },
        color_icons = true,
        separator_style = "slant",
        hover = {
              enabled = true,
              delay = 100,
              reveal = {'close'}
            },
    }
}


vim.notify = require("notify")
require("telescope").load_extension("notify")
local config = {
        background_colour = "NotifyBackground",
        fps = 30,
        icons = {
          DEBUG = "",
          ERROR = "",
          INFO = "",
          TRACE = "✎",
          WARN = ""
        },
        level = "info",
        minimum_width = 25,
        render = "minimal",
        stages = "fade_in_slide_out",
        timeout = 1000,
        top_down = true
      }
vim.notify.setup(config)

local coc_status_record = {}

function coc_status_notify(msg, level)
  -- if message contains cSpell then return
  if string.find(msg, "cSpell") then
    return
  end
  local notify_opts = { title = "LSP Status", timeout = 500, hide_from_history = true, on_close = reset_coc_status_record, icon = "" }
  -- if coc_status_record is not {} then add it to notify_opts to key called "replace"
  if coc_status_record ~= {} then
    notify_opts["replace"] = coc_status_record.id
    notify_opts["hide_from_history"] = true
  end
  coc_status_record = vim.notify(msg, level, notify_opts)
end

function reset_coc_status_record(window)
  coc_status_record = {}
end

local coc_diag_record = {}

function coc_diag_notify(msg, level)
  local notify_opts = { title = "LSP Diagnostics", timeout = 500, on_close = reset_coc_diag_record, icon = "" }
  -- if coc_diag_record is not {} then add it to notify_opts to key called "replace"
  if coc_diag_record ~= {} then
    notify_opts["replace"] = coc_diag_record.id
    notify_opts["hide_from_history"] = true
  end
  coc_diag_record = vim.notify(msg, level, notify_opts)
end

function reset_coc_diag_record(window)
  coc_diag_record = {}
end

function notify(title, msg, level)
  local notify_opts = { title = title, timeout = 500, icon = "!" }
  vim.notify(msg, level, notify_opts)
end

function notify_job(command, opts)
  local output = ""
  local notification
  local notify = function(msg, level, time)
    local notify_opts = vim.tbl_extend(
      "keep",
      opts or {},
      { title = table.concat(command, " "),
        icon = "",
        timeout = time, 
        replace = notification,
        hide_from_history = true,
      }
    )
    notification = vim.notify(msg, level, notify_opts)
  end
  local on_data = function(_, data)
    output = output .. table.concat(data, "\n")
    -- remove all lines from output except the last 30 and save those to output
    local lines = vim.split(output, "\n")
    local num_lines = vim.fn.len(lines)
    if num_lines > 30 then
      local start_idx = num_lines - 30 + 1
      local end_idx = num_lines
      output = table.concat(lines, "\n", start_idx, end_idx)
    end
    notify(output, "info", false)
  end

    -- Prepare the command to run with Bash
  local command_str = table.concat(command, " ")
  local bash_command = {"bash", "--norc", "--noprofile", "-c", command_str}

  vim.fn.jobstart(bash_command, {
    on_stdout = on_data,
    on_stderr = on_data,
    on_exit = function(_, code)
      if #output == 0 then
        notify("No output of command, exit code: " .. code, "warn", 1000)
      elseif code ~= 0 then
        notify(output, "error", 5000)
      else
        notify(output, "info", 2000)
      end
    end,
  })
end

require"octo".setup()

require("early-retirement").setup({
  retirementAgeMins = 120,
  notificationOnAutoClose = true,
})

function input_args(args, arg_values, callback, cmd)
  if #args == 0 then
    vim.call(callback, cmd, arg_values)
    return
  end
  local arg_name, required = unpack(args[1])
  vim.ui.input({prompt = arg_name .. ': '}, function(input_value)
    -- cancel on escape
    if input_value == nil then
      notify("󰌌 Input", "Command cancelled.", "warn")
      return
    elseif input_value ~= '' then
      table.insert(arg_values, input_value)
      input_args({unpack(args, 2)}, arg_values, callback, cmd)
    elseif required then
      notify("󰌌 Input", "Required argument " .. arg_name .. " is missing.", "error")
    else
      input_args({unpack(args, 2)}, arg_values, callback, cmd)
    end
  end)
end

function select_choice(choices, callback)
  vim.ui.select(choices, {}, function(selected_choice, choice_idx)
    if selected_choice == nil then
      notify("󰄴 Selection", "Command cancelled.", "warn")
      return
    else
      vim.call(callback, selected_choice)
    end
  end)
end

function select_buffer_or_cancel(callback, cmd)
  local visual_mode = vim.fn.visualmode()
  if visual_mode ~= 'V' and visual_mode ~= '' then 
    vim.ui.select({"Yes", "No"}, {
      prompt = "No visual selection, run on whole buffer?"
    }, function(choice, choice_idx)
      if choice == "Yes" then
        vim.cmd("normal! ggVG")
        vim.cmd("normal! <esc>")
        vim.call(callback, cmd)
      end
    end)
  else
    vim.call(callback, cmd)
  end
end

if vim.env.OPENAI_API_KEY ~= nil then
  local CodeGPTModule = require("codegpt")
  require("codegpt.config")

  -- until the plugin integrates with tiktoken
  -- assume 1 token = 4 characters of text
  -- as a rule of thumb
  local gpt_4_config = {
    model = "gpt-4-turbo",
    max_tokens = 4096,
    temperature = 0.1,
  }

  local gpt_4_commands = {
    "completion",
    "code_edit",
    "debug",
    "opt",
    "tests",
    "chat",
  }

  local gpt_3_5_config = {
    model = "gpt-3.5-turbo",
    max_tokens = 4096,
    temperature = 0.1,
  }

  local gpt_3_5_commands = {
    "explain",
    "question",
    "doc",
  }
  
  local override_config = vim.g["codegpt_commands_defaults"]

  for _, command in ipairs(gpt_4_commands) do
    -- and merge it with gpt-4-config
    override_config[command] = vim.tbl_extend("force", vim.g.codegpt_commands_defaults[command], gpt_4_config)
  end

  for _, command in ipairs(gpt_3_5_commands) do
    -- and merge it with gpt-3.5-config
    override_config[command] = vim.tbl_extend("force", vim.g.codegpt_commands_defaults[command], gpt_3_5_config)
  end

  vim.g["codegpt_commands_defaults"] = override_config

  vim.g["codegpt_commands"] = {
    ["refactor"] = {
      user_message_template = "I have the following {{language}} code: ```{{filetype}}\n{{text_selection}}```\nRefactor the above code to reduce it's complexity and improve maintainability and code reuse. Add new methods if needed to improve modularity. Only return the code snippet. {{language_instructions}}",
      callback_type = "replace_lines",
      model = gpt_4_config.model,
      max_tokens = gpt_4_config.max_tokens,
      temperature = gpt_4_config.temperature,
    },
    ["simplify"] = {
      user_message_template = "I have the following {{language}} code: ```{{filetype}}\n{{text_selection}}```\nSimplify the above code to reduce it's complexity by reducing repetition, excessive branching, logic etc. Only return the code snippet. {{language_instructions}}",
      callback_type = "replace_lines",
      model = gpt_4_config.model,
      max_tokens = gpt_4_config.max_tokens,
      temperature = gpt_4_config.temperature,
    },
    ["grammar"] = {
      user_message_template = "I have the following {{language}} text: ```{{filetype}}\n{{text_selection}}```\nFix typos, grammatical errors and improve prose. Only return the text snippet. {{language_instructions}}",
      callback_type = "replace_lines",
    },
    ["fix"] = {
      user_message_template = "I have the following {{language}} code: ```{{filetype}}\n{{text_selection}}```\nAutomatically check for potential issues in the code and fix them. Only return the code snippet. {{language_instructions}}",
      callback_type = "replace_lines",
      model = gpt_4_config.model,
      max_tokens = gpt_4_config.max_tokens,
      temperature = gpt_4_config.temperature,
    }
  }

  local chatgpt_diag_record = {}
  local timer = vim.loop.new_timer()
  local timer_counter = 0

  vim.g["codegpt_hooks"] = {
    request_started = function()
      local notify_opts = { title = "ChatGPT", timeout = 2000, on_close = reset_chatgpt_diag_record, icon = "ﮧ" }
      if chatgpt_diag_record ~= {} then
        notify_opts["replace"] = chatgpt_diag_record.id
        notify_opts["hide_from_history"] = true
      end
      local msg = "Requesting"
      chatgpt_diag_record = vim.notify(msg, "info", notify_opts)
      if not timer:is_active() then
        -- start a timer to update the notification every 100ms
        timer:start(100, 100, vim.schedule_wrap(function()
          if chatgpt_diag_record ~= {} then
            notify_opts["replace"] = chatgpt_diag_record.id
            notify_opts["hide_from_history"] = true
          end
          local msg = "Please wait"
          local time_elapsed = timer_counter * 0.1
          msg = msg .. " | " .. time_elapsed .. "s"
          local status = CodeGPTModule.get_status()
          if status ~= "" then
            msg = msg .. " | " .. status
          end
          chatgpt_diag_record = vim.notify(msg, "info", notify_opts)
          if timer_counter == 3600 then
            reset_chatgpt_diag_record()
          end
          timer_counter = timer_counter + 1
        end))
      end
    end,
    request_finished = vim.schedule_wrap(function()
      local notify_opts = { title = "ChatGPT", timeout = 1000, icon = "ﮧ" }
      vim.notify("Request finished", "info", notify_opts)
      reset_chatgpt_diag_record()
    end)
  }

  function reset_chatgpt_diag_record(window)
    timer:stop()
    timer_counter = 0
    chatgpt_diag_record = {}
  end

  vim.g["codegpt_popup_type"] = "horizontal"
else
   notify("🤖 ChatGPT", "OPENAI_API_KEY is not set", "warn")
end

require('gitsigns').setup()

require('hlslens').setup({
  calm_down = true,
})
local kopts = {noremap = true, silent = true}

vim.api.nvim_set_keymap('n', 'n',
    [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
    kopts)
vim.api.nvim_set_keymap('n', 'N',
    [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
    kopts)
vim.api.nvim_set_keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', '<Leader>l', '<Cmd>noh<CR>', kopts)

function _G.symbol_line()
  local curwin = vim.g.statusline_winid or 0
  local curbuf = vim.api.nvim_win_get_buf(curwin)
  local ok, line = pcall(vim.api.nvim_buf_get_var, curbuf, 'coc_symbol_line')
  return ok and line or ''
end

vim.o.winbar = '%!v:lua.symbol_line()'

require("scrollbar").setup({
    handle = {
        text = " ",
        blend = 0, -- Integer between 0 and 100. 0 for fully opaque and 100 to full transparent. Defaults to 30.
        color = nil,
        color_nr = nil, -- cterm
        highlight = "Visual",
        hide_if_all_visible = true, -- Hides handle if all lines are visible
    },
    excluded_filetypes = {
        "prompt",
        "TelescopePrompt",
        "noice",
        "coc-explorer",
    },
    handlers = {
        cursor = true,
        diagnostic = true,
        gitsigns = false,
        handle = true,
        search = true,
    },
})

require('tmux-awesome-manager').setup({
  per_project_commands = { -- Configure your per project servers with
      aperture = { { cmd = 'make generate-config-markdown', name = 'Make' } },
  },
  session_name = 'Neovim Terminals',
  use_icon = true, -- use prefix icon
  icon = ' ', -- Prefix icon to use
  project_open_as = 'separated_session', -- Open per_project_commands as.  Default: separated_session
  default_size = '30%', -- on panes, the default size
  open_new_as = 'pane' -- open new command as.  options: pane, window, separated_session.
})

tmux = require('tmux-awesome-manager')

vim.keymap.set('v', 'l', tmux.send_text_to, {}) -- Send text to a open terminal?
vim.keymap.set('n', 'lo', tmux.switch_orientation, {}) -- Open new panes as vertical / horizontal?
vim.keymap.set('n', 'lp', tmux.switch_open_as, {}) -- Open new terminals as panes or windows?
vim.keymap.set('n', 'lk', tmux.kill_all_terms, {}) -- Kill all open terms.
vim.keymap.set('n', 'l!', tmux.run_project_terms, {}) -- Run the per project commands
vim.keymap.set('n', 'lf', function() vim.cmd(":Telescope tmux-awesome-manager list_terms") end, {}) -- List all terminals
vim.keymap.set('n', 'll', function() vim.cmd(":Telescope tmux-awesome-manager list_open_terms") end, {}) -- List open terminals

tmux_term = require('tmux-awesome-manager.src.term')

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
    call add(l:msgs, '󰋼 Infos: ' . l:info['information'])
  endif
  if get(l:info, 'hint', 0)
    call add(l:msgs, ' Hints: ' . l:info['hint'])
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
  call v:lua.notify_job(cmd)
endfunction

" Vim function that detects local Makefile and its targets
" and asks the user which target to execute
function! SelectMakeTarget()
  " Check if Makefile exists in the current directory
  if !filereadable("Makefile")
    echo "No Makefile found in the current directory"
    return
  endif

  " Extract targets from the Makefile
let l:makefile_lines = readfile("Makefile")
let l:targets = []
for l:line in l:makefile_lines
  " Match lines that have a target name followed by a colon, but ignore those that start with a comment, include a variable assignment, contain a wildcard, .PHONY or a variable
  if l:line =~ '^\s*\([^#:=*$@%]\+\s*:\)\@=' && l:line !~ '^\s*\w\+\s*[:?+]?=\|^\s*\w\+\s*:=\|^\s*#' && l:line !~ '^\s*\.PHONY'
    " Extract the target name without leading/trailing spaces
    let l:target = matchstr(l:line, '^\s*\zs[^#:=\s]\+\ze\s*:')
    " Skip empty entries
    if !empty(l:target)
      call add(l:targets, l:target)
    endif
  endif
endfor

  " Select target using inputlist() in vim or select_choice() in nvim
  if has('nvim')
    call luaeval('select_choice(_A.targets, "ExecuteMakeTarget")', {'targets': l:targets})
  else
    let l:choice = inputlist(map(copy(l:targets), 'v:key + 1 . ". " . v:val'))
    if l:choice >= 1 && l:choice <= len(l:targets)
      call ExecuteMakeTarget(l:targets[l:choice - 1])
    endif
  endif
endfunction

function! ExecuteMakeTarget(target)
  " Execute the selected target using luaeval and tmux
  let l:done = '\n\nDone!'
  call luaeval('tmux.execute_command({ cmd = "(make ' . a:target . ' && echo; echo; echo Done) || (echo; echo; echo Failed)", name = "Make", use_cwd = true })')
endfunction


" Tree sitter based folding
"set foldmethod=expr
"set foldexpr=nvim_treesitter#foldexpr()
