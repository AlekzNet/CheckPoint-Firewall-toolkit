#!/bin/bash

# List of firewalls in the form of:
# IP-address name

FWS=cp.list

# username and password are here just for
# the demo purposes. Use certs.
USERNAME=admin
PASSWD=L1passwd

# Or uncomment the lines below to enter the login
# info interactively

#echo -n "Enter the username: "
#read -e  USERNAME
#echo -n "Enter the SSH password: "
#read -s -e PASSWD
#echo -ne '\n'

TIMESTAMP=`date +'%Y%m%d_%H%M'`

while read fw
do
        set $fw
        mkdir -p $2
        OUTFILE=$2/$2
        cp.exp $1 $2 $USERNAME $PASSWD $ENABLE ${OUTFILE}_${TIMESTAMP} &
done < $FWS
