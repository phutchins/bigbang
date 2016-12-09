#!/bin/bash

# Init BigBang
# This script should determine what OS you're running, and set up the necessary
# bits for installing chef-zero.

## Check out big bang to .bigbang (allow to choose location during setup?)

##
# Import Helpers
# Can't import helpers yet as we're curling this script...

USERNAME=`whoami`
echo "USERNAME: $USERNAME"
HOME_DIR_ENV=`su - $USERNAME -c /usr/bin/env | grep "^HOME="`
echo "HOME_DIR_ENV: $HOME_DIR_ENV"
HOME_DIR=`echo ${HOME_DIR_ENV##*=}`
echo "HOME_DIR: $HOME_DIR"
BASE_DIR="$HOME_DIR/.bigbang"
echo "BASE_DIR: $BASE_DIR"
BASE_DIR2="~/.bigbang"

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

echo "We're running on $OS $platform"

# Should break this and isinstalled() out into a lib file
install()
{
  if [ -z "$1" ] ; then
    echo "Must supply package to install"
  else
    PACKAGE=$1
    echo "Installing package $PACKAGE"

		if [[ $platform == 'linux' ]]; then
			if [[ $OS == 'Ubuntu' ]]; then
        dpkg -s $PACKAGE >/dev/null 2>&1
				if [ $? -ne 0 ] ; then
					echo "Installing $PACKAGE"
					sudo apt-get -y install $PACKAGE
        else
          echo "$PACKAGE already installed"
				fi
			elif [[ $OS == 'CentOS' ]]; then
        yum list installed | grep $PACKAGE >/dev/null 2>&1
				if [ $? -ne 0 ]; then
					echo "Installing $PACKAGE"
					sudo yum -y install $PACKAGE
        else
          echo "$PACKAGE already installed"
				fi
			elif [[ $OS == 'ARCH' ]]; then
        pacman -Qs $PACKAGE >/dev/null 2>&1
				if [ $? -ne 0 ]; then
					echo "Installing $PACKAGE"
					sudo pacman -S --noconfirm $PACKAGE
        else
          echo "$PACKAGE already installed"
				fi
			fi
		elif [[ $platform == 'osx' ]]; then
			if [ ! -f /usr/local/bin/brew ]; then
        echo "Installing Brew..."
				ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
			fi
			if ! [ "brew list -1 | grep -q \"^${PACKAGE}\\\$\"" ]; then
				brew install $PACKAGE
			fi
		fi
  fi
}

# Check out the repo so we can run against our cookbooks
install git;
if ! [ -d "$HOME/.bigbang" ] ; then
  git clone https://github.com/phutchins/bigbang.git ~/.bigbang
fi

ruby_install_type='system'

if [ $ruby_install_type = 'rvm' ]; then
  # Need to install vendored ruby here (installing rvm for now...)
  rvm -v>/dev/null 2>&1
  RVM_EXIT=$?
  if [[ $RVM_EXIT != 0 ]]; then
    echo "RVM is not installed. Installing RVM and Ruby Stable."
    echo "Adding keyserver for RVM"
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 >/dev/null 2>&1
    echo "Installing RVM"
    curl -sSL https://get.rvm.io | bash -s stable --ruby=2.3.3 >/dev/null 2>&1
    echo "Sourcing RVM script so we can start using ruby"
    source /usr/local/rvm/scripts/rvm
  else
    echo "RVM is already installed"
  fi
else
  apt-get update
  apt-get install -y ruby2.3 ruby2.3-dev ruby-dev build-essential
fi

# Install bundler
if ! bundle -v >/dev/null 2>&1; then
  echo "Installing bundler"
  # Installing bundler with gem so we can pin it to avoid a bug
  gem install bundler -v 1.13.6;

  #install bundler -v 1.12.5;
  # Don't want to bundle here
  # bundle install --path vendor/bundle
  # bundle install --binstubs
fi

# Install chef
if ! gem list -i chef >/dev/null 2>&1; then
  echo "Installing Chef..."
  gem install chef >/dev/null 2>&1
  echo "done."
else
  echo "Chef Gem already installed."
fi

# Hack to downgrade Bundler to avoid bug w/ chef
#gem uninstall -aIx bundler
#gem install bundler -v 1.12.5;

# Check for ruby

# Install chef-zero
if ! gem list -i chef-zero >/dev/null 2>&1; then
  echo "Installing Chef Zero..."
  result=$(gem install chef-zero)
  if [[ "$result" != '0' ]] ; then
    echo "Error installing chef-zero"
    exit 1;
  fi
  # Detect if this failed
  echo "done."
else
  echo "Chef Zero Gem already installed."
fi

# Should use curl here to run the ruh.sh script in case we don't want
# to check out the repo

# Want to be able to only pull the users specified initial cookbook,
# do the bundle install and berks install and go

echo "Running Runner from $BASE_DIR/run.sh ..."

# Run chef-zero using env var for run_list
export HOME=$HOME_DIR
env

. $BASE_DIR/run.sh
