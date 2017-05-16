#!/usr/bin/env bash
ssh rlin@aboydfd.com 'cd blog; git pull -r;sudo docker-compose build;sudo docker-compose up -d'
