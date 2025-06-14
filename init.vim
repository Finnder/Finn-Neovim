command! -nargs=* Git G <args>

" ========== Basic Settings ==========
set nocompatible
filetype plugin indent on
syntax on

set number
set relativenumber

set tabstop=4       " Number of spaces a tab counts for"
set shiftwidth=4    " Number of spaces used for auto-indent'
set expandtab       " Use spaces instead of tabs"


let mapleader = " "

" ========== Plugin Manager ==========
call plug#begin('~/.local/share/nvim/plugged')

"FZF for file searching
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-fugitive'

" Multi line edit plugin
Plug 'mg979/vim-visual-multi'

" Treesitter plugin for better syntax
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" Colorschemes
Plug 'morhetz/gruvbox'                     " Gruvbox
Plug 'sainnhe/everforest'                  " Everforest
Plug 'jnurmine/Zenburn'                    " Zenburn

" Completion engine
Plug 'hrsh7th/nvim-cmp'

" Completion sources
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'


" LSP config
Plug 'neovim/nvim-lspconfig'

call plug#end()

colorscheme everforest

autocmd BufReadPost,BufNewFile * :TSEnable highlight

nmap <leader>n  <Plug>(VM-Find-Under)

" === Status Line ===
function! GitBranch()
 let l:branch = system('git rev-parse --abbrev-ref HEAD 2>/dev/null')
 return len(l:branch) ? substitute(l:branch, '\n', '', '') : ''
endfunction

set statusline=
set statusline+=%#PmenuSel#
set statusline+=%{mode()}        " Mode
set statusline+=\ %f             " Filename
set statusline+=\ [%l:%c]        " Line:Column
set statusline+=\ [%{GitBranch()}]  " Git branch

" ========== Key Mappings ==========

" Use <Tab> to indent in visual mode
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

" Disable Space in visual mode / command mode
vnoremap <Space> <Nop>

" Make ; open command mode like :
nnoremap ; :

" FZF keybinding
nnoremap <leader>p :Files<CR>
nnoremap <leader>l :BLines<CR>
nnoremap <leader>o :Rg<CR>

" Single leader scrolls with PageUp/PageDown
nnoremap <leader>k <PageUp>
nnoremap <leader>j <PageDown>

" Double leader scrolls with <C-u>/<C-d>
nnoremap <leader><leader>k <C-u>
nnoremap <leader><leader>j <C-d>

vnoremap <leader>r "zy:lua ReplaceWord()<CR>
vnoremap <leader>R "zy:lua ReplaceExact()<CR>
vnoremap <leader>e "zy:lua ExtractToFile()<CR>

nnoremap <leader>gc :lua GitCommitWithPrompt()<CR>
nnoremap <leader>ga :Git add -A<CR>
nnoremap <leader>gbr :Git branch -r<CR>
nnoremap <leader>gb :Git branch<CR>

" Copy word under cursor to clipboard
nnoremap <leader>c viw"+y

" Copy visual selection to clipboard
vnoremap <leader>c "+y

nnoremap <Tab> >>
nnoremap <S-Tab> <<



lua << EOF
-- Set up nvim-cmp.
local cmp = require'cmp'

cmp.setup({
 snippet = {
   expand = function(args)
     require'luasnip'.lsp_expand(args.body)
   end,
 },
 mapping = cmp.mapping.preset.insert({
   ['<Tab>'] = cmp.mapping.select_next_item(),
   ['<S-Tab>'] = cmp.mapping.select_prev_item(),
   ['<CR>'] = cmp.mapping.confirm({ select = true }),
   ['<C-Space>'] = cmp.mapping.complete(),
 }),
 sources = cmp.config.sources({
   { name = 'nvim_lsp' },
   { name = 'luasnip' },
 }, {
   { name = 'buffer' },
   { name = 'path' }
 })

})

cmp.setup.cmdline(':', {
 mapping = cmp.mapping.preset.cmdline(),
 sources = {
   { name = 'path' },
   { name = 'cmdline' }
 }
})

EOF

lua << EOF
-- Replace exact word under visual selection (whole word match)
function ReplaceWord()
 local word = vim.fn.getreg('"')
 local replacement = vim.fn.input("Replace word '" .. word .. "' with: ")
 if replacement == "" then return end
 vim.cmd('%s/\\<\\V' .. vim.fn.escape(word, '\\') .. '\\>/' .. replacement .. '/g')
end

-- Replace all exact occurrences of selected text
function ReplaceExact()
 local old = vim.fn.getreg('"')
 local replacement = vim.fn.input("Replace '" .. old .. "' with: ")
 if replacement == "" then return end
 vim.cmd('%s/\\V' .. vim.fn.escape(old, '\\') .. '/' .. replacement .. '/g')
end
EOF

lua << EOF
function GitCommitWithPrompt()
 local msg = vim.fn.input("Commit message: ")
 if msg ~= "" then
   vim.cmd("Git commit -m \"" .. msg .. "\"")
 end
end
EOF

lua << EOF
function ExtractToFile()
 local filename = vim.fn.input("Extract to file: ", "", "file")
 if filename == "" then return end

 -- Save selected text to /tmp/tmp_extract.txt
 local temp_path = "/tmp/tmp_extract.txt"
 local content = vim.fn.getreg('z')
 local f = io.open(temp_path, "w")
 if f then
   f:write(content)
   f:close()
 else
   print("Could not write to temp file")
   return
 end

 -- Launch tmux pane with nvim and preload the content
 local cmd = string.format(
   "tmux split-window -h 'nvim %s -c \"0r %s\"'",
   filename,
   temp_path
 )
 os.execute(cmd)
end
EOF

