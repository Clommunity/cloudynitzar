#!/bin/sh
LOGDIR="/var/log/cloudy/"
LOGFILE="cloudynitzar.log"
[ -s $LOGDIR/$LOGFILE ] && exit 0 || exit 1
