##ml_debug

Gather ML debug info

###Usage

```
ml_debug print : print some debug info
ml_debug tar   : create debug tarball
```

This tool can be run directly from github using the following syntax:
```
bash <(curl -s https://raw.github.com/jocisco/ml/master/ml_debug) print 
bash <(curl -s https://raw.github.com/jocisco/ml/master/ml_debug) tar 
```

##ml

ML operational script.

###Usage
```
ml <parameter>
  start  : Starts the ML web werver and datastore daemon
  stop   : Stops the ML web server and datastore daemon
  restart: Restarts the ML web server and datastore daemon
  kill   : Ungracefully aborts the ML processes [kill -KILL]
  status : Simple overview of running ML processes
  top    : Runs top for the ML processes
  test   : Checks if the web server is reachable on port 8080
  config : Displays a simple overview of the MLD config paramaters
```

This tool can be run directly from github using the following syntax:
```
  bash <(curl -s https://raw.github.com/jocisco/ml/master/ml)
```
