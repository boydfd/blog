#!/usr/bin/env bash
ssh rlin@aboydfd.com 'cd blog; git pull -r;sudo bash ./build.sh site;sudo docker-compose up -d'
