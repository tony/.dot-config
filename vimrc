set noswapfile
set viminfo=

if maparg('<C-L>', 'n') ==# ''
  nnoremap <silent> <C-L> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>
endif

" bootstrap neobundle
execute 'source' expand('~/.vim/bootstrap.vim')

call Bootstrap_neobundle_begin()

NeoBundle 'sickill/vim-monokai',
	\ {'script_type': 'colorscheme' }

if executable('ghc-mod') || executable('ghc')
  NeoBundleLazy 'dag/vim2hs', {
        \ 'autoload' : {
        \   'filetypes' : 'haskell',
        \ }}


  NeoBundleLazy 'eagletmt/ghcmod-vim', {
        \ 'autoload' : {
        \   'filetypes' : 'haskell',
        \ }}

  NeoBundleLazy 'ujihisa/neco-ghc', {
        \ 'autoload' : {
        \   'filetypes' : 'haskell',
        \ }}

  NeoBundleLazy 'Twinside/vim-hoogle', {
        \ 'autoload' : {
        \   'filetypes' : 'haskell',
        \ }}

  NeoBundleLazy 'carlohamalainen/ghcimportedfrom-vim', {
        \ 'autoload' : {
        \   'filetypes' : 'haskell',
        \ }}
endif

call Bootstrap_neobundle_end()

syntax enable
colorscheme monokai

" vim: ft=vim
