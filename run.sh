#!/usr/bin/env bash

BASE_DIR=$(pwd)

echo "Running BigBang"

# Prompt the user for group or options to run

# Set correct permissions on /usr/local for homebrew
echo "Setting correct permissions for homebrew in /usr/local"
sudo chown -R `whoami`:staff /usr/local

# Install Berkshelf
if ! gem list berkshelf; then
  echo "Installing Berkshelf..."
  gem install berkshelf
  echo "Done."
fi

# Run Berkshelf to get all the needed cookbooks
echo "Installing/updating cookbooks"
cd $BASE_DIR/cookbooks/base && berks install

# Use berkshelf to vendor cookbooks into the vendor_cookbooks dir
cd $BASE_DIR/cookbooks/base && berks vendor $BASE_DIR/vendor_cookbooks

# Run base bigbang recipe
cd $BASE_DIR && chef-client -z -j config/client.rb -r "recipe[base]"

# Run user selected recipe
