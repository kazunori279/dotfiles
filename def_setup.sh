#!/bin/bash

#
# Default setups
#

# install default tools
sudo apt-get update
sudo apt-get -y install tmux git curl build-essential python-dev

# init git
curl https://raw.githubusercontent.com/kazunori279/dotfiles/master/gitconfig -o ~/.gitconfig
mkdir ~/git
git init

# install pip
curl -kL https://raw.github.com/pypa/pip/master/contrib/get-pip.py | sudo python

# init go
mkdir ~/go
curl https://raw.githubusercontent.com/kazunori279/dotfiles/master/bash_profile -o ~/.bash_profile
curl https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz -o /tmp/golang.tar.gz
sudo tar -C /usr/local -xzf /tmp/golang.tar.gz

