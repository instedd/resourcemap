#!/usr/bin/env bash

# Install Apache2 Passenger module from precompiled binaries
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
apt-get install -y apt-transport-https ca-certificates

# Add our APT repository
echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main" > /etc/apt/sources.list.d/passenger.list
apt-get update

# Install Passenger + Apache module
apt-get install -y libapache2-mod-passenger

# Enable module in Apache2
a2enmod passenger
apache2ctl restart
