#!/binsh

if [ -d $HOME/.cabal ]; then
    pathprepend ~/.cabal/bin
fi
