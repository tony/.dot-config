if [ -d $HOME/gocode ]; then
    export GOPATH=$HOME/gocode
    if [ -d $GOPATH/bin ]; then
        pathprepend $GOPATH/bin
    fi
fi
