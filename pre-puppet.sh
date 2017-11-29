#!/bin/bash
#https://github.com/ffnord/ffnord-puppet-gateway
# adapt IPV6 first!
# do dpkg-reconfigure tzdata

NAME="Freifunk Kiel"
OPERATOR="Freifunk Nord e.V."
CHANGELOG="https://issues.freifunk.in-kiel.de/projects/ffki/issues/"
HOST_PREFIX="ffki-"
SUBDOMAIN_PREFIX=gw
VPN_NUMBER=5
DOMAIN="kiel.freifunk.net"
SUDOUSERNAME="debian"
TLD=ffki

#backborts einbauen
echo "deb http://http.debian.net/debian jessie-backports main" >>/etc/apt/sources.list

#sysupgrade
apt-get update && apt-get dist-upgrade && apt-get upgrade

#MOTD setzen
rm /etc/motd
echo "*********************************************************" >>/etc/motd
echo " $NAME - Gateway $VPN_NUMBER.$SUBDOMAIN_PREFIX.$DOMAIN $NAME " >>/etc/motd
echo " Hoster: $OPERATOR *" >>/etc/motd
echo "*******************************************************" >>/etc/motd
echo " " >>/etc/motd
echo " Changelog: " >>/etc/motd
echo " $CHANGELOG " >>/etc/motd
echo " *" >>/etc/motd
echo " Happy Hacking! *" >>/etc/motd
echo "**********************************************************" >>/etc/motd

#Hostname setzen
hostname $HOST_PREFIX$VPN_NUMBER
#echo "127.0.1.1 $SUBDOMAIN_PREFIX$VPN_NUMBER.$DOMAIN $HOST_PREFIX$VPN_NUMBER" >>/etc/hosts
rm /etc/hostname
touch /etc/hostname
echo "vpn$VPN_NUMBER" >>/etc/hostname

# install needed packages
apt-get -y install sudo apt-transport-https git nload

# optional pre installed to speed up the setup:
apt-get -y install bash-completion haveged sshguard tcpdump mtr-tiny vim nano unp mlocate screen tmux cmake build-essential libcap-dev pkg-config libgps-dev python3 ethtool lsb-release zip locales-all ccze ncdu

#not needed packages from standard OVH template
apt-get -y remove nginx nginx-full exim mutt

#puppet modules install
apt-get -y install --no-install-recommends puppet
puppet module install puppetlabs-stdlib --version 4.15.0 && \
puppet module install puppetlabs-apt --version 1.5.2 && \
puppet module install puppetlabs-vcsrepo --version 1.3.2 && \
puppet module install saz-sudo --version 4.1.0 && \
puppet module install torrancew-account --version 0.1.0
cd /etc/puppet/modules
git clone https://github.com/ffnord/ffnord-puppet-gateway ffnord

# symlink check-install script
ln -s /etc/puppet/modules/ffnord/files/usr/local/bin/check-services /usr/local/bin/check-services

# add aliases
cat <<-EOF>> /root/.bashrc
  export LS_OPTIONS='--color=auto'
  eval " \`dircolors\`"
  alias ls='ls \$LS_OPTIONS'
  alias ll='ls \$LS_OPTIONS -lah'
  alias l='ls \$LS_OPTIONS -lA'
  alias grep="grep --color=auto"
  # let us only use aptitude on gateways
  alias ..="cd .."
  # set nano to (S=)smooth scrolling and (i=)autoindent (T=)2 tabs (E=)as spaces
  # history settings
  HISTCONTROL=ignoreboth
  HISTSIZE=10000
  HISTFILESIZE=200000
EOF

# back in /root
cd /root

echo load the ip_tables and ip_conntrack module
modprobe ip_conntrack
echo ip_conntrack >> /etc/modules

#online script
touch /usr/local/bin/online
cat <<-EOF>> /usr/local/bin/online
#!/bin/bash

maintenance off && service ntp start && batctl -m bat-ffki gw server 100000/100000 && check-services
EOF
chmod +x /usr/local/bin/online

#OVH network config
cat <<-EOF>> /etc/network/interfaces

iface eth0 inet6 static
       address 2001:41d0:701:1000::27c
       netmask 128
       post-up /sbin/ip -6 route add 2001:41d0:701:1000::1 dev eth0
       post-up /sbin/ip -6 route add default via 2001:41d0:701:1000::1 dev eth0
       pre-down /sbin/ip -6 route del default via 2001:41d0:701:1000::1 dev eth0
       pre-down /sbin/ip -6 route del 2001:41d0:701:1000::1 dev eth0

auto eth1
allow-hotplug eth1
iface eth1 inet dhcp
EOF

#USER TODO:
echo 'make sure /root/fastd_secret.key exists'
echo 'adapt IPV6 adress'
echo '####################################################################################'
echo '########### don´t run the following scripts without screen sesssion!!! #############'
echo '####################################################################################'
cat $(dirname $0 )/README.md