#!/bin/bash

### Global variables needed for the configuration process

# The Cloudynitzar application name
APPNAME="Cloudynitzar"

# Debian/Ubuntu release name (e.g. jessie, stretch)
DISTNAME=$(lsb_release -is)

# Debian/Ubuntu release name (e.g. jessie, stretch, trusty)
RELEASENAME=$(lsb_release -cs)

# Use packages from the "main" and "contrib" sections of the Debian repositories
DEBSECTIONS="main contrib"

# The directory where external APT .list files are saved
SOURCESLISTDDIR=/etc/apt/sources.list.d/

# ??? (TODO)
LBMAKEPACKAGES="https://raw.githubusercontent.com/Clommunity/lbmake/master/packages"

# List of Cloudy packages to install
CLOUDYPACKAGES="cDistro.chroot serf.chroot ipfs.chroot"

# List of deprecated Cloudy packages not to be installed
OLDCLOUDYPACKAGES="getinconf-client.chroot"

# List of required Debian/Ubuntu packages for the Cloudynization process
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
	gpg --keyserver keys.gnupg.net --recv-key $1 && gpg --export --armor $1 | apt-key add -
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

# Specific actions for Debian Jessie:
jessie() {
	# Activate shell for www-data so that this user can execute commands
	chsh -s /bin/sh www-data
	chsh -s /bin/sh nobody
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

# Add Backports repository (only Debian)
[ "$DISTNAME" == 'Debian' ] && {
	echo "[$APPNAME] - Adding ${RELEASENAME}-backports repository..."
	echo "deb http://ftp.debian.org/debian ${RELEASENAME}-backports ${DEBSECTIONS}" > ${SOURCESLISTDDIR}/backports.list
}

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

# Upgrade Debian/Ubuntu packages without install recommended packages
echo "[$APPNAME] - Upgrading $DISTNAME packages..."
#apt-get upgrade -qy --no-install-recommends
echo ""

# Install Debian/Ubuntu packages
echo "[$APPNAME] - Installing Debian packages needed for Cloudy..."
while IFS=': ' read name pkgs;
do
	echo "[$APPNAME] - Installing packages required by $name"
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

# Call the function named as the release to perform release-specific changes
echo "[$APPNAME] - Performing specific changes for $DISTNAME $RELEASENAME..."
[ "$(type -t $RELEASENAME)" == "function" ] && $RELEASENAME

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
