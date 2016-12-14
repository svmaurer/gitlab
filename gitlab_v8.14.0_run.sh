#!/bin/bash

# variables for persistent storage
echo ""
config="/home/persistent/gitlab/config"
logs="/home/persistent/gitlab/logs"
data="/home/persistent/gitlab/data"

if [ -d $config ] ; then
echo "$config .. OK"
else
mkdir -p $config
echo "creating $config .. OK"
fi

if [ -d $logs/reconfigure ] ; then
echo "$logs .. OK"
echo "$logs/reconfigure .. OK"
else
mkdir -p $logs/reconfigure
echo "creating $logs .. OK"
echo "creating $logs/reconfigure .. OK"
fi

if [ -d $data ] ; then
echo "$data .. OK"
else
mkdir -p $data
echo "creating $data .. OK"
fi

echo ""


docker run --detach \
    --hostname gitlab \
    --publish 20443:443 --publish 20080:20080 --publish 20080:22 \
    --name gitlab \
    --restart always \
    --link dbgit_run \
    --volume $config:/etc/gitlab:Z \
    --volume $logs:/var/log/gitlab:Z \
    --volume $data:/var/opt/gitlab:Z \
    --volume $logs/reconfigure:/var/log/gitlab/reconfigure:Z \
    gitlab_v8.14.0
