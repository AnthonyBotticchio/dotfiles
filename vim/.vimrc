set tabstop=4       " Number of spaces that a <Tab> in the file counts for
set shiftwidth=4    " Number of spaces to use for each step of (auto)indent
set softtabstop=4   " Number of spaces that a <Tab> counts for while performing editing operations
set expandtab       " Converts tabs to spaces

" Search
set hlsearch        " Highlight all matches
set incsearch       " Highlight matches while typing the search

" Bindings
nnoremap <leader>h :nohlsearch<CR>
nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>y "+y
vnoremap <leader>d "+d

" Windowing
highlight Normal ctermbg=NONE
highlight NonText ctermbg=NONE
