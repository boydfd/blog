---
layout:     post
title:      'Jenkins Docker Docker Docker'
subtitle:   'Jenkins的全套Docker使用'
author:     boydfd
tags:       CI
category:   CI
date: 2018-03-10 08:19:00 +0800
---

# 为什么标题这么奇怪？

之前都是使用Gocd来作为CI的工具，但是Jenkins是目前使用最火的CI工具，所以想研究研究。作为一个有梦想的咸鱼，不想简简单单地走一遍官方教程，就设定了一个target，Pipeline的每一步都使用Docker来做。所以标题的意思就是，用Jenkins做CI工具，用Docker来测试，用Docker来Build，用Docker来Deploy。

# 简介

1. 这次会用Spring项目来做示范，进行全套的CI流程。这是本次项目使用的[代码库](https://github.com/boydfd/jenkins_docker_spring)
2. 所有的需求就是装好docker，能使用git的。

#1. Set up Jenkins

##1. Install Jenkins in docker

	docker run \
    --restart=always \
    -d \
    -u root \
    -p 8888:8080 \
    -v jenkins-data:/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$HOME":/home \
    jenkinsci/blueocean
    
解释一下几个重要的参数:
1. -u root 用root作为容器的用户
2. -p 8888:8080 将本机8888端口映射到容器内部的8080端口
3. -v jenkins-data:/var/jenkins_home 将jenkins-data volume映射到/var/jenkins_home。 这是做持久化用的
4. （很重要）/var/run/docker.sock:/var/run/docker.sock 这个参数将本机的docker.sock映射到容器内的docker
.sock，这样就可以在容器内部使用docker来在本机启动一个容器了。
5. -v "$HOME":/home （暂时还没发现有什么用）
6. jenkinsci/blueocean 这是带blueocean的Jenkins容器。blueocean提供了更漂亮的界面。

##2. Login Jenkins
装完后，可以访问[http://localhost:8888](http://localhost:8888)看到:  
![Login page](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/portal.png)

按照提示找到密码然后填入

##3. Initialize Jenkins
登录后，可以看到初始化界面:  
![Initialization page](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/Initialization.png)

这里选择Install suggested plugins

##4. Register
装完后就出现了注册界面，可以注册第一个admin账号:
![Register page](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/register.png)

## Set up repository 
好的，Jenkins的环境准备完毕，来准备一下代码库（我们默认使用github来做代码库）。
目前代码库只需要一个README就行了。

#2. Set up pipeline

1. 打开blue ocean：
![Blue ocean page](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/open-blue-ocean.png)
2. 点击Create a new Pipeline。
3. 点击GitHub
4. 点击"Create an access key here."来创建Jenkins用于访问GitHub的Access token
5. 输入github密码
6. 取个token名
7. 将token填入Jenkins并点击connect
8. 选好组织
9. 选好repository
10. 点击"Create Pipeline"。
11. 设置好pipeline：
	1. 将Start的agent设置为none,因为我们之后要在不同的stage使用不同的agent（也就是不同的docker image）:
![Pipeline start](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/pipeline-start.png)
	2. 添加一个hello world的stage：
		1. 点击页面左边的加号
		2. 在页面右边输入stage名字
		3. 点击add step
		4. 选择Shell Script
		5. 输入: echo 'hello world':
		![Pipeline steps](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/hello-world-stage-steps.png)
		6. 点击Settings
		7. 选择agent为docker
		8. image填busybox:
		![Pipeline settings](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/hello-world-stage-settings.png)
		9. 点击save
		10. 点击Save&run:
		![Pipeline commit](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/hello-world-stage-commit.png)
		11. 等一小会儿，我们的第一个pipeline就变绿了。再check一下我们的git仓库，里面多了一条commit，以及Jenkinsfile:
		![Spring hello world stage](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/spring-hello-world-stage.png)
	3. 现在我们的pipeline还没法自动触发，我们可以点击小齿轮，进入pipeline的设置，然后设置Scan Repository Triggers为1分钟：
		![Pipeline Trigger Setting](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/pipeline-trigger-setting.png)
	
#3. Add Test Stage
在准备好代码库和pipeline后，我们可以加入我们的第一个test stage了。

1. 在Jenkinsfile中加入新的stage：

	```groovy
	stage('Test') {
		agent {
			docker {
				image 'java:8-jdk-alpine'
			}
		}
		steps {
			sh './gradlew clean test'
		}
	}
	```
	因为我们的代码库里面什么都没有，所以pipeline肯定会红。
	
2. 在代码库中引入spring,并确保本地`./gradlew clean test`可以通过。
3. push代码，等待pipeline被trigger。
4. 打开jenkins，发现pipeline已经过了：
![Pipeline Success 1](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/pipeline-success1.png)

5. 仔细看一下Test stage的log，发现了各种download依赖，我们需要想个办法保存这些依赖，作为gradle项目，直接将~/.gradle映射到容器中去就行了：

	```groovy
	stage('Test') {
		agent {
			docker {
				image 'java:8-jdk-alpine'
				args '-v /home/jenkins/.gradle:/root/.gradle'
			}
		}
		steps {
			sh './gradlew clean test'
		}
	}
	```

6. 但是我们现在点击Pipeline里的Test，发现：
![No Test Report](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/no-test-report.png)
所以现在我们加上Test报告:

	```groovy
	stage('Test') {
		agent {
			docker {
				image 'java:8-jdk-alpine'
				args '-v /home/jenkins/.gradle:/root/.gradle'
			}
		}
		steps {
			sh './gradlew clean test'
		}
		post {
			always {
				junit 'build/test-results/**/*.xml'
			}
		}
	}
	```

![All pass test Report](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/all-pass-test-report.png)

7. 赶紧写一个Fail Test来试试我们的报告效果:

	```java
		@Test
		public void shouldFail() {
			assertEquals("expected value","wrong value");
		}
	```

![Test fail Report](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/test-fail-report.png)

8. 把我们的这个fail test删掉~~~~~

#4. add build stage
在我们的Jenkinsfile里加上build stage：
```groovy
stage('Build') {
	agent {
		docker {
			image 'java:8-jdk-alpine'
			args '-v /home/jenkins/.gradle:/root/.gradle'
		}
	}
	steps {
		sh './gradlew clean build'
	}
	post {
		success {
			archiveArtifacts artifacts: 'build/libs/*.jar', fingerprint: true
		}
	}
}
```
post块里的代码会让我们将build出来的包给保存下来。

补充说明：其实gradle build的时候会跑test，所以可以只留一个stage。

#5. add build docker image stage
1. 在这个stage我们需要把之前的jar包copy出来，所以需要Copy Artifact插件：
	1. 依次打开：Manage Jenkins -> Manage Plugins
    2. 使用filter 搜索**Copy Artifact**并安装
2. 添加Dockerfile:
	```dockerfile
	FROM java:8-jdk-alpine
	VOLUME /tmp
	COPY entrypoint.sh entrypoint.sh
	RUN chmod +x entrypoint.sh
	COPY app.jar app.jar
	ENTRYPOINT ["./entrypoint.sh"]
	```
	entrypoint.sh:
	```bash
	#!/bin/sh
	java -jar -Dspring.profiles.active=$springProfiles /app.jar
	```
3. 添加build的脚本：
	build.sh
	```bash
	#!/usr/bin/env sh

	dockerRegistry='192.168.42.10:5000'
	imageName=jenkins_docker_spring
	cd $(dirname $([ -L $0 ] && readlink -f $0 || echo $0))


	set -x
	docker build -t "$dockerRegistry/$imageName" .
	docker push "$dockerRegistry/$imageName"
	set +x
	cd -
	```
4. 在Jenkinsfile里添加新的stage：

	```groovy
	stage('Build Docker') {
		agent {
			docker {
				image 'docker:stable'
				args '-v /var/run/docker.sock:/var/run/docker.sock'
			}
		}
		steps {
			step([$class              : 'CopyArtifact',
				  filter              : 'build/libs/*.jar',
				  fingerprintArtifacts: true,
				  projectName         : '${JOB_NAME}',
				  selector            : [$class: 'SpecificBuildSelector', buildNumber: '${BUILD_NUMBER}']
			])

			sh 'cp build/libs/*.jar docker/app.jar'
			sh 'docker/build.sh app.jar'
		}
	}
	```

一些重要的解释：
1. 在docker容器中使用docker的时候，需要加上这个映射  

	`args '-v /var/run/docker.sock:/var/run/docker.sock'`
	
2. 这个地方是在调用jenkins的插件，主要作用就是将上个stage的jar拷贝到这个stage中去。
	```groovy
	step([$class              : 'CopyArtifact',
		  filter              : 'build/libs/*.jar',
		  fingerprintArtifacts: true,
		  projectName         : '${JOB_NAME}',
		  selector            : [$class: 'SpecificBuildSelector', buildNumber: '${BUILD_NUMBER}']
	])
	```

#6. add deploy stage
最后就是deploy了，一般的部署方式都很简单k8s和rancher都可以有http的方式来部署，这里我们使用ssh的方式登录到目标机器来部署（虽然不是好的实践，但是可以了解一下这样的方式）

1. 我们需要在Jenkins里安装一个插件：
	1. 依次打开：Manage Jenkins -> Manage Plugins
	2. 使用filter 搜索**Publish Over SSH**并安装
2. 给**Publish Over SSH**设置我们的ssh private key。
	1. 依次打开：Manage Jenkins -> Configure System
	2. 在**Publish over SSH**section进行配置
	
![Ssh configuration](https://github.com/boydfd/pictures/raw/master/jenkins-docker-docker-docker/ssh-configuration.png)
3. 在Jenkinsfile里面新加一个Deploy stage:

	```groovy
	stage('Deploy') {
		agent {
			docker { image 'busybox' }
		}
		steps {
			sshPublisher(publishers: [sshPublisherDesc(
							configName: 'configuration1',
							transfers: [sshTransfer(execCommand: 'echo 111')])])
		}
	 }
	```
	sshPublisher相当于调用Publish Over SSH的函数:
		1. configName: 对应插件配置里的Name。
		2. execCommand: 登录目标机器后想执行的命令。这里我只是echo了一下。
	
#7. 结束语

学好docker，走遍天下都不怕。只需要一台装有docker的机器，我们的jenkins就能完美运行了。