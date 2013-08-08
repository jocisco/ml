#!/bin/bash

#############################################################################
##
## Name
##	ml
##
## Author
##	Jonathan Garzon
##
## Description
##	start / stop / check script for MATE Live daemons	
##
## History:
## 0.1 JG 09/29/2012: Initial version
## 1.0 BM 06/14/2012: Several modifications to harden & make fit for server deployment
##
#############################################################################

#Source the env var's:
#. $HOME/.bash_profile

# Check if $CARIDEN_ROOT is defined
[ -z $CARIDEN_ROOT ] && CARIDEN_ROOT="-undefined-"

test_path=`which license_check &>/dev/null` 
if [[ $? == 1 ]]; then
	echo Please add MATE bin directory to your PATH.
	echo "e.g.  export PATH=\"\$PATH:/opt/cariden/software/mate/current/bin\""                    
	exit
fi

# Determining package location
PACKAGE_DIR=`echo $test_path | sed 's/\(.*\)\/bin\/license_check/\1/'`


# Returns the path to a particular MATE config file
# Requires $CARIDEN_ROOT and $PACKAGE_DIR to be set
function mate_path {
        for path in "$CARIDEN_ROOT" "$HOME/.cariden" "$PACKAGE_DIR" ;
        do
                [ -f $path/$1 ] && { echo "$path/$1"; break; }
        done
}

# Variables to be set. Modified as required:
CONFIG_FILE=`mate_path /etc/matelive/ml.conf`

if [[ ! -r $CONFIG_FILE ]]; then
    echo ML Config file not found.
    exit;
fi

# Define $MLDB:
set_mldb_env() {
    MLDB=`cat $CONFIG_FILE | grep Datastore= | cut -f2 -d'='`
    if [[ ! $MLDB ]]; then
        MLDB=`cat $CONFIG_FILE | grep MLData= | cut -f2 -d'='`/datastore
    fi
}
set_mldb_env

TOMCAT=`ps aux | grep bin/java | grep apache-tomcat | grep -v grep | grep start | awk '{print $2}'`
MLDX=`ps aux | grep mld_x | grep -v grep | awk '{ print $1 + $2 }'`
SLICE=`ps aux | grep mld_slice | grep -v grep | awk '{ print $1 + $2 }'`

matelive_top() {
    if [[ ! $TOMCAT || ! $MLDX || ! $SLICE ]]; then
        echo ERROR: Not all ML processes are running. Aborting ML Top.
        exit;
    fi
    top -p $TOMCAT -p $MLDX -p $SLICE
}

matelive_status() {
    echo "*** MATE Live status ***"
    if [[ $TOMCAT ]]; then
        echo Tomcat up and running. pid: $TOMCAT
    else
        echo Tomcat not running.
    fi
    if [[ $MLDX ]]; then
        echo mld_x up and running. pid: $MLDX
    else
        echo mld_x not running.
    fi
    if [[ $SLICE ]]; then
        echo mld_slice up and running. pid: $SLICE
    else
        echo mld_slice not running.
    fi
}

matelive_kill() {
    echo killing tomcat pid: $TOMCAT
    kill -KILL $TOMCAT
    echo killing mld_x pid: $MLDX
    kill -KILL $MLDX
}

matelive_stop() {
    if [[ ! $TOMCAT && ! $MLDX && ! $SLICE ]]; then
        echo MATE Live not running.
    fi
    if [[ $TOMCAT ]]; then 
        echo "*** stopping web server (pid: $TOMCAT) ***"
        #echo WARNING: embedded_web_server -action stop does not seem to work! BUG?
        #echo sending KILL signal instead.
        #kill -KILL $TOMCAT
        $CARIDEN_HOME/bin/embedded_web_server -action stop -verbosity 40
        while [[ `ps  -p $TOMCAT | wc -l` != 1 ]]; do echo -n .; sleep 1; done; echo
    fi
    if [[ $MLDX ]]; then
        echo "*** stopping mld (pid:$MLDX) ***"
        $CARIDEN_HOME/bin/mld -datastore $MLDB -action stop -verbosity 40
        while [[ `ps -p $MLDX | wc -l` != 1 ]]; do echo -n .; sleep 1; done; echo
    fi
}

matelive_start() {
    if [[ $MLDX ]]; then
        echo NOTICE: mld_x already running.
    else
        echo "*** starting mld ***"
        $CARIDEN_HOME/bin/mld -datastore $MLDB -verbosity 40
    fi
    if [[ $TOMCAT ]]; then
        echo NOTICE: Tomcat already running.
    else
        echo "*** starting web server ***"
        $CARIDEN_HOME/bin/embedded_web_server -action start -verbosity 40
    fi
    /opt/cariden/Cariden/bin/ml status
}

usage() {
    echo Usage:
    echo "  start  : Starts the ML web werver and datastore daemon";
    echo "  stop   : Stops the ML web server and datastore daemon";
    echo "  restart: Restarts the ML web server and datastore daemon";
    echo "  kill   : Ungracefully aborts the ML processes [kill -KILL]";
    echo "  status : Simple overview of running ML processes";
    echo "  top    : Runs top for the ML processes";
    echo "  test   : Checks if the web server is reachable on port 8080";
    echo "  config : Displays a simple overview of the MLD config paramaters";

}

for i in $*
do
	case $i in
        start)
                matelive_start
                exit
                ;;
        stop)
                matelive_stop 
                exit
                ;;
        kill)
                matelive_kill
                exit
                ;;
        restart)
                matelive_stop
                TOMCAT=''
                MLDX=''
                SLICE=''
                matelive_start
                exit
                ;;
        status)
                matelive_status
                exit
                ;;
        top)
                matelive_top
                exit
                ;;
        test)
                curl http://localhost:8080/matelive/
                exit
                ;;
        config)
                echo "Current config file:"
                ls -al $CONFIG_FILE | sed 's,^[^/]*,,'
                echo '------------------'
                cat $CONFIG_FILE | grep -v '^#' | grep -v ^$
                echo '------------------'
                exit
                ;;
    	*)
                echo Unknown option: $i;
                usage
                exit
		;;
  	esac
done

usage
