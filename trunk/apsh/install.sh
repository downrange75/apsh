#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

mkdir -p /etc/apsh /usr/local/lib/perl

cp apsh apscp /usr/local/bin/.
cp APSH.pm /usr/local/lib/perl/.
cp nodes.tab /etc/apsh

chmod +x /usr/local/bin/apsh /usr/local/bin/apscp
