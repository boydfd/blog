#!/usr/bin/env bash
check_git_changed_file() {
	siteShouldRebuild=0
	for dir in $(
		echo $(
			for path in $(git diff --name-only "${1}^..${2}")
			do
				echo $(dirname "$path")
			done
		) | xargs -n1 | sort -u
	)
	do
		case $dir in
			nginx)
				rebuildNginx
				;;
			_posts)
				updatePost
				;;
			*)
				siteShouldRebuild=1
				;;
		esac
	done
	if [ $siteShouldRebuild = 1 ];
	then
		rebuildSite
	fi
}
rebuildNginx() {
	echo 'rebuild nginx'
	sshRemote 'cd blog;sudo docker-compose build nginx;sudo docker-compose up -d'
}

rebuildSite() {
	echo 'rebuild site'
	sshRemote 'cd blog;sudo docker-compose build site;sudo docker-compose up -d'
}

updatePost() {
	echo updatePost
}

sshRemote() {
	pemPath=~/certs/aboydfd.pem
	if [ -f ${pemPath} ];
	then
		echo 'use pem file'
		sshKey="-i $pemPath"
	fi
	ssh ${sshKey} rlin@aboydfd.com "$1"
}
rebuild() {
	sshRemote 'cd blog;sudo docker-compose build;sudo docker-compose up -d'
}
update() {
	sshRemote 'cd blog; git pull -r'
}
case $1 in
	init)
		sudo docker-compose build; sudo docker-compose up -d
		;;
	bsite)
		rebuildSite
		;;
	bnginx)
		rebuildNginx
		;;
	update)
		update
		;;
	*)
		check_git_changed_file $GO_FROM_REVISION_BLOG $GO_TO_REVISION_BLOG
		;;
esac
