containerName=blog
imageName=blog
workDir=blog
builtDir='_build'
build() {
	sed s/{{builtDir}}/${builtDir}/g ./Dockerfile.template > Dockerfile
	docker build -t $imageName .
}

run() {
	docker rm -f $containerName
    docker run --name $containerName -v $(pwd)/${builtDir}:/${workDir}/${builtDir} -p 4000:8000 $imageName
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
