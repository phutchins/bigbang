#!/usr/bin/env bash

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

gem_install()
{
  if [ -z "$1" ] ; then
    echo "Must supply gem name to install"
  fi

  GEM=$1

  gem list -i $GEM >/dev/null 2>&1
  if [ $? -ne 0 ] ; then
    echo "Installing Gem $GEM"
    gem install $GEM
  else
    echo "Gem $GEM already installed..."
  fi
}
