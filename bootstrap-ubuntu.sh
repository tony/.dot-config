sudo apt-get install tmux cmake ninja-build rxvt-unicode-256color \
cowsay \
fortune-mod \
pgadmin3 \
vim-nox \
ctags \
silversearcher-ag \
wget \
git \
tig \
most \
entr \
curl \
openssh-server \
build-essential \
pgadmin3 \
postgresql-10 \
htop \
virtualbox \
fonts-noto-cjk \
xfonts-wqy


sudo apt install python3.7


curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -
sudo apt-get install -y nodejs



# 1. Add the Spotify repository signing keys to be able to verify downloaded packages
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0DF731E45CE24F27EEEB1450EFDC8610341D9410

# 2. Add the Spotify repository
echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list


# 4. Install Spotify
sudo apt-get install spotify-client

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt-get update
sudo apt-get install yarn

# https://github.com/golang/go/wiki/Ubuntu
sudo add-apt-repository ppa:gophers/archive
sudo apt update
sudo apt-get install golang-1.11-go

GOEXPORT='export PATH=$PATH:/usr/lib/go-1.11/bin'
grep -q -F "$GOEXPORT" ~/.profile || echo "$GOEXPORT" >> ~/.profile 
