containerName=blog
imageName=blog
build() {
	docker build -t $imageName .
}

run() {
	docker rm -f $containerName
    docker run --name $containerName -p 4000:8000 $imageName
}

buildRun() {
	build
	run
}
case $1 in
	-b)
		build
		;;
	-r)
		run
		;;
	-br)
		buildRun
		;;
	-rb)
		buildRun
		;;
esac
