awsapp
======

app for aws:reinvent demo

Requirements
============

To run the app you will need to compile Docker from source using the `aws-driver` branch on this repo (so that you will have access to the `docker hosts` command).  Make sure it is in your `$PATH` as `docker`.  Also make sure to set your AWS account credentials the correct way in environment variables.

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

