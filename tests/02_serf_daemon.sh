#!/bin/sh
/opt/serf/serf version | grep "Serf" && exit 0
exit 1
