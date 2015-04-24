#!/bin/bash

#
# Default setups
#

# install default tools
sudo apt-get update
sudo apt-get -y install tmux git golang curl 

# init git
curl https://raw.githubusercontent.com/kazunori279/dotfiles/master/gitconfig -o ~/.gitconfig
mkdir ~/git
git init

# init go
mkdir ~/go
echo "export GOPATH=~/go" > ~/.bash_profile
source ~/.bash_profile

