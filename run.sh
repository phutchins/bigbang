#!/usr/bin/env bash
# This script should provide you with options for what to install/run if in
# interactive mode, and if not, it should run chef zero with the specified
# runlist via ENV variable.

# Command line ENV Options
# BIGBANG_MODE - [ ZERO ] BOOTSTRAP
# TARGET - [ GCP ] N/A

# GCP Metadata Options
# CHEF_VALIDATION_BASE64
# CHEF_RUN_LIST
# CHEF_SERVER
# CHEF_VALIDATION_NAME
# CHEF_ENVIRONMENT

#BASE_DIR=$(pwd)
BASE_DIR=$HOME/.bigbang

# Import Helpers
. $BASE_DIR/util.sh --source-only

# Defaults
DEFAULT_CHEF_ZERO_RUN_LIST="recipe[base]"
DEFAULT_CHEF_RUN_LIST=""
DEFAULT_MODE=ZERO

# Should specify this via env if you want it true
CONFIG_INTERACTIVE_MODE=${INTERACTIVE_MODE:false}
CONFIG_HOSTNAME=$(hostname)

# Should we bother getting this config mode from the metadata api?
CONFIG_MODE=${BIGBANG_MODE:-$DEFAULT_MODE}


# Set the bigbang run list
# If we're in ZERO mode, we just use the rulist provided
if [[ $CONFIG_MODE == "ZERO" ]] ; then
  echo "Running in CONFIG mode ZERO"
  CONFIG_CHEF_ZERO_RUN_LIST=${CHEF_RUN_LIST:-$DEFAULT_CHEF_ZERO_RUN_LIST}
fi

# If we're in BOOTSTRAP mode, we set the bigbang runlist to 'recipe[chef_bootstrap_self]'
# and use the supplied runlist to pass along to chef-client
if [[ $CONFIG_MODE == "BOOTSTRAP" ]] ; then
  echo "Running in CONFIG mode BOOTSTRAP"
  CONFIG_CHEF_ZERO_RUN_LIST="recipe[chef_bootstrap_self]"
  CONFIG_CHEF_RUN_LIST=${CHEF_RUN_LIST:-$DEFAULT_CHEF_RUN_LIST}
fi


echo "Running with run_list '$CONFIG_CHEF_RUN_LIST'"

if [[ $CONFIG_INTERACTIVE_MODE == "true" ]] ; then
	echo "Running BigBang in Interactive mode"

  # Run interactive mode function
  interactive;
else
  echo "Running BigBang in Non Interactive mode"
fi

interactive()
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

gem_install berkshelf

# Run Berkshelf to get all the needed cookbooks
# Should only need to do this if running a local cookbook
echo "Installing/updating cookbooks"
cd $BASE_DIR/cookbooks/base && berks install

# Use berkshelf to vendor cookbooks into the vendor_cookbooks dir
if ! [ -d $BASE_DIR/vendor_cookbooks ]; then
  mkdir $BASE_DIR/vendor_cookbooks;
fi

cd $BASE_DIR/cookbooks/base && berks vendor $BASE_DIR/vendor_cookbooks

# Run base bigbang recipe
cd $BASE_DIR && chef-client -z -j config/client.rb -r $CONFIG_CHEF_ZERO_RUN_LIST

# Run user selected recipe
