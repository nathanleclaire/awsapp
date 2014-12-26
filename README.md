__TAKE NOTE__: This demo currently relies on the `docker hosts` functionality and concept, which for a variety of reasons is now a totally separate tool called `machine`.  The `machine` repo is at https://github.com/docker/machine and I intend to port this demo over at some point, but I haven't yet.  The concepts are essentially the same (i.e. how to do a rolling deploy using `hosts` / `machine` and Docker) if you want to take a stab at your own, but it will take a little bit of time before this particular repo can be used out of the box.


awsapp
======

app for aws:reinvent demo

Requirements
============

To run the app you will need to compile Docker from source using the `aws-driver` branch on [nathanleclaire/docker](http://github.com/nathanleclaire/docker) (so that you will have access to the `docker hosts` command).  Make sure it is in your `$PATH` as `docker`.  Also make sure to set your AWS account credentials the correct way in environment variables.

Usage
=====

Setup infrastructure:

```
./deploy.sh up
```

Deploy the app:

```
./deploy.sh deploy
```

Rollback to a known image tag:

```
./deploy.sh rollback Thu_Nov_13_22_49_34_UTC_2014
```

Un-bootstrap (destroy) infrastructure:

```
./deploy.sh down
```

