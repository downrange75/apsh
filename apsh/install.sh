#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ ! -d /usr/local/lib/perl ]
then
   echo "Creating directory /usr/local/lib/perl..."
   mkdir -p /usr/local/lib/perl
fi

if [ ! -d /etc/apsh ]
then
   echo "Creating directory /etc/apsh..."
   mkdir -p /etc/apsh
fi

echo "Installing apsh and apscp..."
cp apsh apscp /usr/local/bin/.
echo "Installing APSH.pm..."
cp APSH.pm /usr/local/lib/perl/.

if [ ! -f /etc/apsh/nodes.tab ]
then
   echo "Installing base nodes.tab..."
   cp nodes.tab /etc/apsh
fi

chmod +x /usr/local/bin/apsh /usr/local/bin/apscp
