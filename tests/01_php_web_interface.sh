#!/bin/sh
curl http://localhost:7000 | grep -i cloudy | grep -i clommunity | grep -i netcommons && exit 0
exit 1
