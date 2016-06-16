#!/usr/bin/env bash

# Init BigBang
## Check out big bang to .bigbang (allow to choose location during setup?)

##

# Determine what OS we're running on
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
   platform='linux'
   if [ -f /usr/bin/lsb_release ]; then
     OS=$(lsb_release -si)
     ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
     VER=$(lsb_release -sr)
     # Need to detect ARCH here with uname -r
   elif [ -f /etc/os-release ]; then
     source /etc/os-release
     #OS=$(uname -r | sed s/[0-9.-]*//)
     if [[ $ID == 'antergos' ]]; then
       OS='ARCH'
     fi
   fi
elif [[ "$unamestr" == 'Darwin' ]]; then
   platform='osx'
fi

# Need to install vendored ruby here

# Install chef
if ! gem list --local chef >/dev/null 2>&1; then
  echo "Installing Chef..."
  gem install chef >/dev/null 2>&1
  echo "done."
else
  echo "Chef Gem already installed."
fi

# Install chef-zero
if ! gem list --local chef-zero >/dev/null 2>&1; then
  echo "Installing Chef Zero..."
  result=$(gem install chef-zero)
  # Detect if this failed
  echo "done."
else
  echo "Chef Zero Gem already installed."
fi

# Run chef-zero using env var for run_list
./run.sh
