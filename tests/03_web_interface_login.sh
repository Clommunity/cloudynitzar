#!/bin/sh
PASSWORD="cloudy"
echo "$(whoami):$PASSWORD" | (sudo chpasswd)
curl -d "user=$(whoami)&password=$PASSWORD" -X POST http://localhost:7000 | grep -i cloudy | grep -i clommunity | grep -i netcommons && exit 1
exit 0
