#!/bin/bash

#
# Default setups
#

# install default tools
sudo apt-get update
sudo apt-get -y install tmux git curl 

# init git
curl https://raw.githubusercontent.com/kazunori279/dotfiles/master/gitconfig -o ~/.gitconfig
mkdir ~/git
git init

# init go
mkdir ~/go
curl https://raw.githubusercontent.com/kazunori279/dotfiles/master/bash_profile -o ~/.bash_profile
source ~/.bash_profile
curl https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz -o /tmp/golang.tar.gz
tar -C /usr/local -xzf /tmp/golang.tar.gz

