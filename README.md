# cloudynitzar

### About
Cloudynitzar is a shell script that turns your plain Debian system into a community networking cloud in a box (i.e. a full-featured Cloudy device). It might work on Debian derivatives too, like Ubuntu. Feel free to test and report!

### Requirements
A fresh and updated Debian 9 *Stretch* installation with `curl`, `lsb-release` and an Internet connection.

Cloudynitzar will also work on a Debian 8 *Jessie* installation and may also work on a 7.8 *Wheezy* with the *backports* repository enabled.

### Procedure
From your Debian system run, as root:

````sh
apt-get update; apt-get install -y curl lsb-release
curl -k https://raw.githubusercontent.com/Clommunity/cloudynitzar/master/cloudynitzar.sh | bash -
````

and let the magic begin!
