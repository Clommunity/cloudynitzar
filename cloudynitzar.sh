#!/bin/bash

### Global variables needed for the configuration process

# The Cloudynitzar application name
APPNAME="Cloudynitzar"

# Debian release name (e.g. jessie, stretch)
RELEASENAME=$(lsb_release -cs)

# Use packages from the "main" and "contrib" sections of the Debian repositories
SECTIONS="main contrib"

# The directory where external APT .list files are saved
SOURCESLISTDDIR=/etc/apt/sources.list.d/

# ??? (TODO)
LBMAKEPACKAGES="https://raw.githubusercontent.com/Clommunity/lbmake/master/packages"

# List of Cloudy packages to install
CLOUDYPACKAGES="avahi-ps.chroot cDistro.chroot serf.chroot"

# List of deprecated Cloudy packages not to be installed
OLDCLOUDYPACKAGES="getinconf-client.chroot"

# List of required Debian packages for the Cloudynization process
DEBREQPACKAGES="curl unzip dirmngr"

# URL for lbmake's package hooks' path
LBMAKEHOOKSPATHURL="https://raw.githubusercontent.com/Clommunity/lbmake/master/hooks/"

# CPU architecture (as reported by uname)
ARCH=$(uname -m|sed 's/i.86/i386/'|sed 's/^arm.*/arm/')

# URL for cloudynitzar's distribution- and architecture- related files
DISTURL="https://raw.githubusercontent.com/Clommunity/cloudynitzar/master/dist"

# Curl binary
CURL="/usr/bin/curl"

# File extension for specific cases
SPECIFICS_EXT=".list"


### Global functions for the the Cloudynization process

# ??? (TODO)
get_http_code() {
	$CURL -s -o /dev/null -I -w "%{http_code}" $1
}

# Get a GPG key and add it to the APT keyring
get_key_and_add_apt() {
	gpg --keyserver pgpkeys.mit.edu --recv-key $1 && gpg --export --armor $1 | apt-key add -
}

# Find out which is the primary network interface
get_primary_network_interface() {
	# The network interface providing the Internet default route
	IPRDEFAULT=$(ip route g 8.8.8.8 | grep -Po '(?<=(dev )).*(?= src| proto)')
	# The network interface providing the CN default route
	IPRCN=$(ip route g 10.0.0.0/8 | grep -Po '(?<=(dev )).*(?= src| proto)')

	[ ! -z "$IPRDEFAULT" ] && [ ! -z "$IPRCN" ] && [ "$IPRDEFAULT" == "$IPRCN" ] && echo "$IPRDEFAULT" && return
	[ ! -z "$IPRDEFAULT" ] && [ -z "$IPRCN" ] && echo "$IPRDEFAULT" && return
	[ -z "$IPRDEFAULT" ] && [ ! -z "$IPRCN" ] && echo "$IPRCN" && return
}

# Specific actions for Debian Jessie
jessie() {
	chsh -s /bin/sh www-data
	chsh -s /bin/sh nobody
}

# ??? (TODO)
specifics() {
	[ $(get_http_code "${DISTURL}/${1}/${2}${SPECIFICS_EXT}") == "200" ] && {
		while IFS='|' read name destin mod;
		do
			echo "COPY ${DISTURL}/${1}/${2}/$name -> ${destin}/${name} $mod"
			mkdir -p ${destin}
			$CURL -s "${DISTURL}/${1}/${2}/${name}" -o "${destin}/${name}"
			chmod $mod ${destin}/${name}
		done < <($CURL -s "${DISTURL}/${1}/${2}${SPECIFICS_EXT}")
	}
}


### Beginning of the Cloudynization process

# In case the lsb-release package was not installed and we could not get the
# release name, install it:
echo "[$APPNAME] - Finding out the release name..."
[ -z "$RELEASENAME" ] && { echo "[$APPNAME] - Warning: package lsb-release is not installed."; \
	echo "[$APPNAME] - Updating package lists..."; \
	apt-get -qq update; \
	echo "[$APPNAME] - Installing package lsb-release..."; \
	apt-get install -qy lsb-release; \
	RELEASENAME=$(lsb_release -cs); }

# Last check for the release name
[ -z "$RELEASENAME" ] && { echo "[$APPNAME] - Error: could not determine the current release name. Exiting..."; \
	exit 1; }
echo "[$APPNAME] - The release name is \"$RELEASENAME\""
echo ""

# Update package sources
echo "[$APPNAME] - Updating package sources..."
apt-get -qq update

# Install required packages for the Cloudynization process
echo "[$APPNAME] - Installing required packages for the Cloudynization process..."
apt-get install -qy ${DEBREQPACKAGES}
echo ""

# Add repository source files
echo "[$APPNAME] - Adding repository source files to ${SOURCESLISTDDIR}..."
mkdir -p ${SOURCESLISTDDIR}

# Add Backports repository
echo "[$APPNAME] - Adding ${RELEASENAME}-backports repository..."
echo "deb http://ftp.debian.org/debian ${RELEASENAME}-backports ${SECTIONS}" > ${SOURCESLISTDDIR}/backports.list

# Add Clommuntiy repository
echo "[$APPNAME] - Adding Clommunity repository..."
echo "deb http://repo.clommunity-project.eu/debian unstable/" > ${SOURCESLISTDDIR}/cloudy.list

# Add Guifi repository
echo "[$APPNAME] - Adding Guifi.net repository..."
echo "deb http://serveis.guifi.net/debian guifi/" > ${SOURCESLISTDDIR}/guifi.list
echo ""

# Add Clommunity repository GPG
echo "[$APPNAME] - Adding Clommunity repository GPG key to the local APT keyring..."
get_key_and_add_apt A59C5DC8

# Add Guifi.net repository GPG
echo "[$APPNAME] - Adding Guifi.net repository GPG key to the local APT keyring..."
get_key_and_add_apt 2E484DAB
echo ""

# Update package sources again
echo "[$APPNAME] - Updating package sources with newly added repositories..."
apt-get -qq update
echo ""

# Upgrade Debian packages without install recommended packages
echo "[$APPNAME] - Upgrading Debian packages..."
apt-get upgrade -qy --no-install-recommends
echo ""


# Install Debian packages
echo "[$APPNAME] - Installing Debian packages needed for Cloudy..."
while IFS=': ' read name pkgs;
do
	echo "[$APPNAME] - $name."
	apt-get install -yq $pkgs
done < <($CURL -s $LBMAKEPACKAGES-$RELEASENAME)
echo ""

# Install Cloudy packages
echo "[$APPNAME] - Installing Cloudy software packages..."
for i in $CLOUDYPACKAGES
do
	$CURL -s ${LBMAKEHOOKSPATHURL}$i |ARCH=$ARCH sh -
done
echo ""

# jessie changes
# activar la shell de www-data, per que es puguin executar coses amb su "www-data"...
[ "$(type -t $RELEASENAME)" == "function" ] && $RELEASENAME

specifics $ARCH $RELEASENAME
echo ""


# Detect and save default network interface configuration
echo "[$APPNAME] - Detecting the primary network interface..."
echo "[$APPNAME] - The primary network interface is $(get_primary_network_interface). Saving it..."
echo "PRIMARYINTERFACE=\"$(get_primary_network_interface)\"" >> /etc/cloudy/cloudy.conf
echo ""

# Start Cloudy daemons
echo "[$APPNAME] - Starting Cloudy web interface..."
/etc/init.d/cdistro stop
/etc/init.d/cdistro start
echo ""

echo "[$APPNAME] - Starting Serf..."
/etc/init.d/serf stop
/etc/init.d/serf start
echo ""
