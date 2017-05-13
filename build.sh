
buildSite1() {
	siteContainerName=blog
	siteImage=blog
	siteWorkDir=blog
	builtDir='_build'
	sed s/{{builtDir}}/${builtDir}/g ./Dockerfile.template > Dockerfile
	docker build -t $siteImage .
	rm -f Dockerfile
	docker rm -f $siteContainerName
	docker run --name $siteContainerName -v $(pwd)/${builtDir}:/${siteWorkDir}/${builtDir} $siteImage
	docker images | grep none | awk '{print $3}' | xargs docker rmi
}

buildSite() {
	docker build -f Dockerfile-site -t blog-site .
	docker images | grep none | awk '{print $3}' | xargs docker rmi
}

buildNginx() {
	nginxImage=blog-nginx
	nginxContainerName=blog-nginx
	cp Dockerfile.nginx Dockerfile
	docker build -t $nginxImage .
	rm -f Dockerfile
	docker images | grep none | awk '{print $3}' | xargs docker rmi

}

run() {
	nginxImage=blog-nginx
	nginxContainerName=blog-nginx
	docker rm -f $nginxContainerName
	docker run -d --name $nginxContainerName -v $(pwd)/certs:/etc/nginx/certification -p 80:80 -p 443:443 $nginxImage
}

siteRun() {
	buildSite
	run
}

buildRun() {
	buildSite
	buildNginx
    	run
}
case $1 in
	site)
		buildSite
		;;
	nginx)
		buildNginx
		;;
	build)
		buildSite
		buildNginx
		;;
	run)
    		run
    		;;
	-br)
		buildRun
		;;
	-rb)
		buildRun
		;;
	-sr)
		siteRun
		;;
	-rs)
		siteRun
		;;
esac
