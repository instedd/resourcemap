#!/usr/bin/env bash

source /etc/profile.d/rbenv.sh

rbenv install $1
rbenv shell $1

shift

if (( $# )); then
    rbenv exec gem install $@
fi
