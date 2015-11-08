if [ -d $HOME/gocode ]; then
    export GOPATH=$HOME/gocode
elif [ -d $HOME/work/go ]; then
    export GOPATH=$HOME/work/go
fi

if [ -x $GOPATH ]; then
    if [ -d $GOPATH/bin ]; then
        pathprepend $GOPATH/bin
    fi
fi
