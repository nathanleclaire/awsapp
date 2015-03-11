# awsapp 

![](https://cloud.githubusercontent.com/assets/1476820/5850721/9fde0662-a1af-11e4-9615-3fa3b634bbab.png)

This is a demo of doing a [blue-green
deploy](http://martinfowler.com/bliki/BlueGreenDeployment.html) of a simple web
application using [Docker Machine](https://github.com/docker/machine) and
[Docker](https://github.com/docker/docker) of course.

Orchestration of this deploy is handled using a highly advanced technology known
as the Bourne again shell.

# Requirements

- Working copy of Docker.
- [Docker Machine](https://github.com/docker/machine) installed as `docker-machine` command on your system.

Set the following environment variables:

```
$ export DOCKER_HUB_USER=nathanleclaire # Your username on Docker Hub
$ export AWS_VPC_ID=vpc-fe10ab9b # The default VPC for us-east-1 for your account
$ export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
$ export AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxxx
```

After that, you should be ready to rock and roll.

# Usage

Setup infrastructure (this will create the host and run the initial copy of the
app):

``` 
./deploy.sh up 
```

Deploy the app:

``` 
./deploy.sh deploy 
```

Each deploy will be tagged by timestamp.

What if you deployed and broke everything with terrible code?

No problem.  Just rollback to a known image tag:

``` 
./deploy.sh rollback Thu_Nov_13_22_49_34_UTC_2014 
```

Un-bootstrap (destroy) infrastructure:

``` 
./deploy.sh down 
```

# Architecture

This demo is single-host, but the concepts could be applied to a multi-host
setup with some additional elbow grease (and service discovery).

Two instances of a Flask (Python) application running in containers sit behind a
load balancer (HAproxy).  One exposes the application on the host's
`localhost:8000`, the other exposes the application on the host's
`localhost:8001`.  They are connected to a container running Redis using Docker
links.  

The load balancer happily proxies requests to these backends with a round-robin algorithm.  
Haproxy has a health check set so that if one of the containers stops responding 
at the health check endpoint, it will be taken out of rotation.  So, when it
comes time to do a deploy, first we tell one of the containers to start
responding to HAproxy with a non-200 API status from the health check endpoint.
This allows HAproxy an interval to "catch up" and remove the node from rotation
before we take the container down and replace it with a new one running our new
image (thereby deploying the new code).

All incoming requests get proxied to the "healthy" container while we restart
the "unhealthy" one.  When the node comes back up, it starts responding as
healthy again and we repeat the process for the other node.

This allows us to do a deploy with very little (ideally none) downtime.  You may 
notice that rollbacks to a previous tag are super fast too.
