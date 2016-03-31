# cloudynitzar

### About
Cloudynitzar is a shell script that turns your plain Debian system into a community networking cloud in a box (i.e. a full-featured Cloudy device). It might work on Debian derivatives too, like Ubuntu. Feel free to test and report!

### Requirements
A system with an up-to-date Debian 8 *Jessie* installation (Debian 7.8 *Wheezy* with *backports* may work too) with `curl`, `lsb-release` and an Internet connection.

### Procedure
From your Debian system run, as root:

````sh
apt-get update; apt-get install curl lsb-release
curl -k https://raw.githubusercontent.com/Clommunity/cloudynitzar/master/cloudynitzar.sh | bash -
````

and let the magic begin!
