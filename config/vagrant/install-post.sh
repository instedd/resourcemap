#!/usr/bin/env bash

# Create directories for Capistrano
mkdir -p /u/apps /u/apps/resource_map/shared/config
chown -R vagrant:vagrant /u/apps

# Create empty database
mysql -uroot -e "CREATE DATABASE resource_map"

# Enable Apache2 site configuration
cp /home/vagrant/resource_map.conf /etc/apache2/sites-available
a2ensite resource_map
a2dissite 000-default
service apache2 reload

# Link libzmq.so in a place where ffi-rzmq can find it
ln -nsf /usr/lib/x86_64-linux-gnu/libzmq.so /usr/local/lib
