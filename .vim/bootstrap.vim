

let g:make = 'gmake'
if system('uname -o') =~ '^GNU/'
        let g:make = 'make'
endif

let g:iCanHazNeoBundle=0

function! Has_neobundle()
	let NeoBundle_readme=expand('~/.vim/bundle/neobundle.vim/README.md')
 return filereadable(NeoBundle_readme)
endfunction

function! Bootstrap_neobundle_download()
	" NeoBundle check and auto install


	    echo "Installing NeoBundle.."
	    silent !mkdir -p ~/.vim/bundle
	    silent !git clone https://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim
	    let g:iCanHazNeoBundle=1

endfunction


function! Bootstrap_neobundle_begin()
	" Setting up NeoBundle - the vim plugin bundler
	set nocompatible               " Be iMproved

	if !Has_neobundle()
	call Bootstrap_neobundle_download()
	endif

	if has('vim_starting')
	    set runtimepath+=~/.vim/bundle/neobundle.vim/
	endif

	call neobundle#begin(expand('~/.vim/bundle/'))

	" Let NeoBundle manage NeoBundle
	NeoBundleFetch 'Shougo/neobundle.vim'

	NeoBundle 'Shougo/vimproc.vim', {
	      \   'build' : {
	      \     'windows' : 'tools\\update-dll-mingw',
	      \     'cygwin' : 'make -f make_cygwin.mak',
	      \     'mac' : 'make -f make_mac.mak',
	      \     'linux' : 'make',
	      \     'unix' : g:make,
	      \   }
	      \ }

endfunction

function! Bootstrap_neobundle_end()

	" Installation check.
	if g:iCanHazNeoBundle == 1
	    echo "Installing Bundles, please ignore key map error messages"
	    echo ""
	    :NeoBundleInstall
	endif

	call neobundle#end()

	NeoBundleCheck
endfunction
