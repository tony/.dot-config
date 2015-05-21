FreeBSD 10.1 Battle.net installation through WINE

::

    sudo pkg install wine-devel

::
    
    wine ~/.wine/drive_c/users/Public/Application\ Data/Battle.net/Agent/Agent.beta.2581/Agent.exe --nohttpauth &

while the agent is running, start the Battle.net installer from another terminal than the
agent.I've used the following library overrides in winecfg:

* dbghelp (disabled)
* msvcp100 (native then builtin)

Source: https://forum.winehq.org/viewtopic.php?f=2&t=22769
