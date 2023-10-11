#!/bin/bash

HOST_DATA_FILE=/home/ec2-user/host-data

TOKEN=`curl -s -X PUT http://169.254.169.254/latest/api/token -H X-aws-ec2-metadata-token-ttl-seconds:21600`
PUBLIC_DNS=`curl -s -H X-aws-ec2-metadata-token:$TOKEN -v http://169.254.169.254/latest/meta-data/public-hostname`

OS=`hostnamectl | grep Operating | cut -f2- -d: | xargs`

DOCKER_VERSION=`docker --version`

rm -rf $HOST_DATA_FILE

echo "public-dns: $PUBLIC_DNS" > $HOST_DATA_FILE
echo "host-os: $OS" >> $HOST_DATA_FILE
echo "docker-version: $DOCKER_VERSION" >> $HOST_DATA_FILE
