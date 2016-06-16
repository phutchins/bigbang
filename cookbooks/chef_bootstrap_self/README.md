# chef_bootstrap_self
Bootstraps a node against chef from itself using environment variables for init.

## Usage
+ Set required environment variables in environment
+ Run BigBang curl command on host as root

### Environment Variables
```
RUN_LIST - The run list that the node will have after bootstrap
CHEF_VALIDATOR - The chef validator key which will allow it to bootstrap itself
CHEF_SERVER - The chef server to bootstrap against
```

### BigBang Curl
```
source <(curl -s https://raw.githubusercontent.com/phutchins/bigbang/master/init.sh)
```
