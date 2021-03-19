#!/bin/bash

### Enable logging to a file
LOGDIR="/var/log/cloudy"
LOGFILE="cloudynitzar.log"
sudo mkdir -p $LOGDIR
exec > >(sudo tee -a ${LOGDIR}/${LOGFILE} )
exec 2> >(sudo tee -a ${LOGDIR}/${LOGFILE} >&2)

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
CLOUDYPACKAGES="cDistro.chroot avahi-ps.chroot serf.chroot ipfs.chroot"

# List of deprecated Cloudy packages not to be installed
OLDCLOUDYPACKAGES="getinconf-client.chroot"

# List of required Debian/Ubuntu packages for the Cloudynization process
DEBREQPACKAGES="curl unzip dirmngr iproute2"

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
	sudo $CURL -s -o /dev/null -I -w "%{http_code}" $1
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
	#IPRCN=$(ip route g 10.0.0.0/8 | grep -Po '(?<=(dev )).*(?= src| proto)')
	IPRCN=$(ip route g 10.0.0.0 | grep -Po '(?<=(dev )).*(?= src| proto)') # No /8 for U20

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
echo "Beginning of the Cloudynization process"

# In case the lsb-release package was not installed and we could not get the
# release name, install it:
echo "[$APPNAME] - [$(date)] - Finding out the release name..."
[ -z "$RELEASENAME" ] && { echo "[$APPNAME] - [$(date)] - Warning: package lsb-release is not installed."; \
	echo "[$APPNAME] - [$(date)] - Updating package lists..."; \
	sudo apt-get -qq update; \
	echo "[$APPNAME] - [$(date)] - Installing package lsb-release..."; \
	sudo apt-get install -qy lsb-release; \
	RELEASENAME=$(lsb_release -cs); }

# Last check for the release name
[ -z "$RELEASENAME" ] && { echo "[$APPNAME] - [$(date)] - Error: could not determine the current release name. Exiting..."; \
	exit 1; }
echo "[$APPNAME] - [$(date)] - The release name is \"$RELEASENAME\""
echo ""

# Update package sources
echo "[$APPNAME] - [$(date)] - Updating package sources..."
sudo apt-get -qq update

# Install required packages for the Cloudynization process
echo "Install required packages for the Cloudynization process"
echo "[$APPNAME] - [$(date)] - Installing required packages for the Cloudynization process..."
sudo apt-get install -qy ${DEBREQPACKAGES}
echo ""

# Add repository source files
echo "[$APPNAME] - [$(date)] - Adding repository source files to ${SOURCESLISTDDIR}..."
sudo mkdir -p ${SOURCESLISTDDIR}

# Add Backports repository (only Debian)
[ "$DISTNAME" == 'Debian' ] && {
	sudo echo "[$APPNAME] - [$(date)] - Adding ${RELEASENAME}-backports repository..."
	sudo echo "deb http://ftp.debian.org/debian ${RELEASENAME}-backports ${DEBSECTIONS}" > ${SOURCESLISTDDIR}/backports.list
}

# Add Clommuntiy repository
#echo "[$APPNAME] - [$(date)] - Adding Clommunity repository..."
#sudo echo "deb http://repo.clommunity-project.eu/debian unstable/" > ${SOURCESLISTDDIR}/cloudy.list

# Add Guifi repository
#echo "[$APPNAME] - [$(date)] - Adding Guifi.net repository..."
#sudo echo "deb http://serveis.guifi.net/debian guifi/" > ${SOURCESLISTDDIR}/guifi.list
#echo ""

# Add Clommunity repository GPG
#echo "[$APPNAME] - [$(date)] - Adding Clommunity repository GPG key to the local APT keyring..."
#get_key_and_add_apt A59C5DC8

# Add Guifi.net repository GPG
#echo "[$APPNAME] - [$(date)] - Adding Guifi.net repository GPG key to the local APT keyring..."
#get_key_and_add_apt 2E484DAB
#echo ""

# Update package sources again
echo "[$APPNAME] - [$(date)] - Updating package sources with newly added repositories..."
sudo apt-get -qq update
echo ""

# Upgrade Debian/Ubuntu packages without install recommended packages
echo "[$APPNAME] - [$(date)] - Upgrading $DISTNAME packages..."
#apt-get upgrade -qy --no-install-recommends
echo ""

# Install Debian/Ubuntu packages
echo "[$APPNAME] - [$(date)] - Installing Debian packages needed for Cloudy..."
while IFS=': ' read name pkgs;
do
	echo "[$APPNAME] - [$(date)] - Installing packages required by $name"
	sudo apt-get install -yq $pkgs
done < <(sudo $CURL -s $LBMAKEPACKAGES-$RELEASENAME)
echo ""

# Install Cloudy packages
echo "[$APPNAME] - [$(date)] - Installing Cloudy software packages..."
for i in $CLOUDYPACKAGES
do
	sudo $CURL -s ${LBMAKEHOOKSPATHURL}$i |ARCH=$ARCH sudo sh -
done
echo ""

# Call the function named as the release to perform release-specific changes
echo "[$APPNAME] - [$(date)] - Performing specific changes for $DISTNAME $RELEASENAME..."
[ "$(type -t $RELEASENAME)" == "function" ] && $RELEASENAME

# Detect and save default network interface configuration
echo "[$APPNAME] - [$(date)] - Detecting the primary network interface..."
echo "[$APPNAME] - [$(date)] - The primary network interface is $(get_primary_network_interface). Saving it..."
#sudo echo "PRIMARYINTERFACE=\"$(get_primary_network_interface)\"" >> /etc/cloudy/cloudy.conf
PRIMARYINTERFACE="$(get_primary_network_interface)"
echo "prim interface is $PRIMARYINTERFACE"
#sudo echo $PRIMARYINTERFACE >> /etc/cloudy/cloudy.conf
echo "PRIMARYINTERFACE=\"$(get_primary_network_interface)\""| sudo tee -a /etc/cloudy/cloudy.conf
echo "/etc/cloudy/cloudy.conf"
cat /etc/cloudy/cloudy.conf
echo ""

# Start Cloudy daemons
echo "[$APPNAME] - [$(date)] - Starting Cloudy web interface..."
sudo /etc/init.d/cdistro stop
sudo /etc/init.d/cdistro start
echo ""

echo "[$APPNAME] - [$(date)] - Starting (restarting) Serf..."
sudo /etc/init.d/serf restart
echo ""
