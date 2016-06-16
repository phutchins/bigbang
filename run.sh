#!/usr/bin/env bash

BASE_DIR=$(pwd)
DEFAULT_CHEF_RUN_LIST='recipe[chef-base]'
DEFAULT_INTERACTIVE_MODE=false
CONFIG_CHEF_RUN_LIST=${CHEF_RUN_LIST:-$DEFAULT_CHEF_RUN_LIST}
CONFIG_CHEF_VALIDATION=$CHEF_VALIDATION
CONFIG_CHEF_SERVER=$CHEF_SERVER
CONFIG_INTERACTIVE_MODE=${INTERACTIVE_MODE:-$DEFAULT_INTERACTIVE_MODE}

if [ $CONFIG_INTERACTIVE_MODE = true ] ; then
	echo "Running BigBang in Interactive mode"

  # Run interactive mode function
  interactive;
else
  echo "Running BigBang in Non Interactive mode"
fi

interactive ()
{
  echo "please make a choice"
}

# Prompt the user for group or options to run (only in interactive mode)

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


# Set correct permissions on /usr/local for homebrew
# echo "Setting correct permissions for homebrew in /usr/local"
# Should find a better way to do this so we don't have to ask for sudo pw every time
# Also need to detect OS here
# sudo chown -R `whoami`:staff /usr/local

# Install Berkshelf
if [[ $platform == 'linux' ]]; then
  if [[ $OS == 'Ubuntu' ]]; then
    if ! [ "dpkg -l | grep berkshelf" ] ; then
      echo "Installing Berkshelf"
      sudo apt-get install berkshelf
    fi
  elif [[ $OS == 'CentOS' ]]; then
    if ! [ "yum list installed | grep berkshelf" ]; then
      echo "Installing Berkshelf"
      sudo yum install berkshelf
    fi
  elif [[ $OS == 'ARCH' ]]; then
    if ! [ "which tmux" ]; then
      echo "Installing Berkshelf"
      sudo pacman -S berkshelf
    fi
  fi
elif [[ $platform == 'osx' ]]; then
	if ! gem list berkshelf; then
		echo "Installing Berkshelf..."
		gem install berkshelf
		echo "Done."
	fi
fi

# Run Berkshelf to get all the needed cookbooks
echo "Installing/updating cookbooks"
cd $BASE_DIR/cookbooks/base && berks install

# Use berkshelf to vendor cookbooks into the vendor_cookbooks dir
if ! [ -d $BASE_DIR/vendor_cookbooks ]; then
  mkdir $BASE_DIR/vendor_cookbooks;
fi

cd $BASE_DIR/cookbooks/base && berks vendor $BASE_DIR/vendor_cookbooks

# Run base bigbang recipe
cd $BASE_DIR && chef-client -z -j config/client.rb -r $CONFIG_CHEF_RUN_LIST

# Run user selected recipe
