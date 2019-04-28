WSL notes
=========

Postgres notes
--------------

### WARNING:  could not flush dirty data: Function not implemented

Link: https://github.com/Microsoft/WSL/issues/3863

In postgresql.conf:

```
data_sync_retry = true
```

### Postgres isn't started?

You have to do it manually

```
sudo service postgresql start
```

Battling terminal corruption
----------------------------
with WSL (bash.exe), vim, and tmux

Link: https://github.com/cmderdev/cmder/issues/901#issuecomment-237572842

```
%windir%\system32\bash.exe ~ -c bash -cur_console:p
```

In ConEmu, go into Startup -> Tasks and create a ``Bash::bash`` task

Task params: ``/icon "%USERPROFILE%\AppData\Local\lxss\bash.ico"``

Command (including starting at ``$HOME``):

```
%windir%\system32\bash.exe ~ -c bash -cur_console:p
```


### tmux: use xterm as default terminal

Link: https://github.com/cmderdev/cmder/issues/1178#issuecomment-263598432

```
set -g default-terminal "xterm"
```

### tmux: More sorcery

Link: https://github.com/Maximus5/ConEmu/issues/1786#issuecomment-459748388

```
set -ags terminal-overrides ",xterm-*:csr@"
```


### vim:

Link: https://github.com/cmderdev/cmder/issues/1719#issuecomment-376330584

```viml
if (&term == "pcterm" || &term == "win32")
        set term=xterm t_Co=256
        let &t_AB="\e[48;5;%dm"
        let &t_AF="\e[38;5;%dm"
        set termencoding=utf8
        set nocompatible
        inoremap <Char-0x07F> <BS>
        nnoremap <Char-0x07F> <BS>
endif
" set background=dark
" colorscheme solarized
```
