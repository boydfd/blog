#!/usr/bin/env bash
ssh rlin@35.187.205.160 'cd blog; git pull -r;sudo bash ./build.sh site;sudo docker-compose up -d'