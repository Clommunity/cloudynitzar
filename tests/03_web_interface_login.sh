#!/bin/sh
echo -e "Cloudy\nCloudy" | (sudo passwd travis)
curl -d "user=travis&password=Cloudy" -X POST http://localhost:7000 | grep -i cloudy | grep -i clommunity | grep -i netcommons && exit 1
exit 0
