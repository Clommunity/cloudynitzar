#!/bin/bash

# Agafa variables necessaries
DISTRIBUTION=$(lsb_release -c|cut -f 2)
AREAS="main contrib"
ARCHDIR=/etc/apt/sources.list.d/
LPACKAGES="https://raw.githubusercontent.com/Clommunity/lbmake/master/packages"
CPACKAGES="avahi-ps.chroot cDistro.chroot getinconf-client.chroot serf.chroot"
HOOKPATH="https://raw.githubusercontent.com/Clommunity/lbmake/master/hooks/"
ARCH=$(uname -m|sed 's/i.86/i386/'|sed 's/^arm.*/arm/')
DIST="https://raw.githubusercontent.com/Clommunity/cloudynitzar/master/dist"
CURL="/usr/bin/curl"
SPECIFICS_EXT=".list"

[ -z "$DISTRIBUTION" ] && { apt-get install -y lsb-release; DISTRIBUTION=$(lsb_release -c|cut -f 2); }


# funcions globals
getkey() {
	gpg --keyserver pgpkeys.mit.edu --recv-key $1 && gpg --export --armor $1 | apt-key add -
}

jessie() {
	chsh -s /bin/sh www-data
	chsh -s /bin/sh nobody
}

getHTTPCode() {
	$CURL -s -o /dev/null -I -w "%{http_code}" $1
}

specifics() {
	[ $(getHTTPCode "${DIST}/${1}/${2}${SPECIFICS_EXT}") == "200" ] && {
		while IFS='|' read name destin mod;
		do
			echo "COPY ${DIST}/${1}/${2}/$name -> ${destin}/${name} $mod"
			mkdir -p ${destin}
			$CURL -s "${DIST}/${1}/${2}/${name}" -o "${destin}/${name}"
			chmod $mod ${destin}/${name}
		done < <($CURL -s "${DIST}/${1}/${2}${SPECIFICS_EXT}")
	}
}

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

# Paquets necessaris per l'instal·lació
apt-get update
apt-get upgrade -y --no-install-recommends
apt-get install -y curl unzip


# Instal·lar paquets debian
while IFS=': ' read name pkgs;
do
	echo "Install $name."
	apt-get install -y $pkgs
done < <($CURL -s $LPACKAGES)

# Instal·lar altres paquets

for i in $CPACKAGES
do
	$CURL -s ${HOOKPATH}$i |ARCH=$ARCH sh -
done

# jessie changes
# activar la shell de www-data, per que es puguin executar coses amb su "www-data"...
[ "$(type -t $DISTRIBUTION)" == "function" ] && $DISTRIBUTION

specifics $ARCH $DISTRIBUTION

# Activar daemons
echo "Stop & Start cDistro."
/etc/init.d/cdistro stop
/etc/init.d/cdistro start
echo "Stop & Start SERF."
/etc/init.d/serf stop
/etc/init.d/serf start
