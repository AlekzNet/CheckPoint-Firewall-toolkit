#!/bin/bash
IKEXML="/etc/fw/log/legacy_ikev2.xmll.0"
SAVEDIR="/var/log/ikev2-save"
NEWNAME="${SAVEDIR}/ikev2_`date +'%Y%m%d_%H%M'`.xmll"
NUMFILES=15

mkdir -p $SAVEDIR

if [ -e $IKEXML ] 
then 
        mv $IKEXML $NEWNAME
        gzip $NEWNAME
fi

NFILES=`ls -l ${SAVEDIR}/*.xmll.gz | wc -l`

if [[ $NFILES -ge $NUMFILES ]] 
then  rm `ls -1t ${SAVEDIR}/*.xmll.gz | tail -1`
fi
