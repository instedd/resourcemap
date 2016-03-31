#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Add elastic.co repository for Elasticsearch 1.7
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb http://packages.elastic.co/elasticsearch/1.7/debian stable main" > /etc/apt/sources.list.d/elasticsearch-1.7.list

apt-get update

# Install basic services
# Resourcemap needs:
# - elasticsearch (for indexing collections)
# - redis (for background job queues via resque and some caching)
# - postfix (or any other MTA for sending mail)
# - imagemagick (for custom collections logo manipulation)
apt-get -q -y install mysql-server apache2 postfix imagemagick redis-server
apt-get -q -y install openjdk-7-jre-headless elasticsearch

update-rc.d elasticsearch defaults 95 10
service elasticsearch start

# Install requirements for building Ruby and gems
# libmysqlclient-dev for mysql2
# libgmp-dev for json
# nodejs for coffee-rails
# libzmq3-dev for poirot_rails
# libssl-dev, libsqlite3-dev, libreadline-dev for buidling Ruby
apt-get -q -y install build-essential git libmysqlclient-dev libgmp-dev nodejs libzmq3-dev libssl-dev libsqlite3-dev libreadline-dev
