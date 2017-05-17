#!/usr/bin/env bash

sshRemote() {
	ssh rlin@aboydfd.com "$1"
}
rebuild() {
	sshRemote 'cd blog; git pull -r;sudo docker-compose build;sudo docker-compose up -d'
}
update() {
	echo 1
	echo $GO_TO_REVISION_BLOG
	echo $GO_FROM_REVISION_BLOG
	echo $GO_FROM_REVISION_GOCD
	echo $GO_TO_REVISION_GOCD
	echo 2
	sshRemote 'cd blog; git pull -r'
}
case $1 in
	rebuild)
		rebuild
		;;
	update)
		update
		;;
esac