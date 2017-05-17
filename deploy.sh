#!/usr/bin/env bash

sshRemote() {
	ssh rlin@aboydfd.com "$1"
}
rebuild() {
	set x
	echo 1
	echo $GO_FROM_REVISION_FOO
	echo $GO_TO_REVISION_FOO
	echo 2
	sshRemote 'cd blog; git pull -r;sudo docker-compose build;sudo docker-compose up -d'
}
update() {
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