#!/bin/bash

# Agafa variables necessaries
DISTRIBUTION=$(lsb_release -c|cut -f 2)
AREAS="main contrib"
ARCHDIR=/etc/apt/source.list.d/
LPACKAGES="https://raw.githubusercontent.com/Clommunity/lbmake/master/packages"

CPACKAGES="avahi-ps.chroot cDistro.chroot peerstreamer.chroot serf.chroot getinconf-client.chroot"
HOOKPATH="https://raw.githubusercontent.com/Clommunity/lbmake/master/hooks/"

# funcions globals
getkey() {
	gpg --keyserver pgpkeys.mit.edu --recv-key $1 && gpg --export --armor $1 | apt-key add -
}

jessie() {
	chsh -s /bin/sh www-data
}

# Paquets necessaris per l'instal·lació
apt-get update
apt-get upgrade
apt-get install -y -Y curl 

# Instal·lar Repositoris
mkdir -p ${ARCHDIR}
# Add Backports Repo
echo "deb http://ftp.debian.org/debian ${DISTRIBUTION}-backports ${AREAS}" > ${ARCHDIR}/backports.list
# Add Clommuntiy Repo
echo "deb http://repo.clommunity-project.eu/debian unstable/" > ${ARCHDIR}/cloudy.list
getkey A59C5DC8
# Add Guifi Repo
echo "deb http://serveis.guifi.net/debian guifi/" > ${ARCHDIR}/serveis.list
getkey 2E484DAB

# Instal·lar paquets debian
while IFS=': ' read name pkgs;
do
	echo "Install $name."
	echo "apt-get install -y -Y $pkgs"
done < <(curl -s $LPACKAGES)

# Instal·lar altres paquets

for i in $CPACKAGES
do
	curl -s ${HOOKPATH}$i |sh -
done

# jessie changes
# activar la shell de www-data, per que es puguin executar coses amb su "www-data"...
[ "$(type -t $DISTRIBUTION)102" == "function" ] && $DISTRIBUTION