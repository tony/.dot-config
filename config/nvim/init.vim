if filereadable(expand("~/.vim/.vimrc"))
  exe 'source' expand("~/.vim/.vimrc")
elseif filereadable(expand("~/.vimrc"))
  exe 'source' expand("~/.vimrc")
endif
