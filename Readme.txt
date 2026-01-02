====================================================================
MongoDB ReplicaSet on Kubernetes (Secured)
PURPOSE

This repository provides a production-safe MongoDB ReplicaSet
deployment on Kubernetes with full automation.

Features:

3-node MongoDB ReplicaSet

Internal authentication using keyFile

Admin & application user creation

Headless service for stable DNS

Automated replica-set initialization

Backup & restore scripts

RBAC-secured Kubernetes Jobs

This design avoids:

Manual kubectl exec

Auth lockout issues

Unstable primary election

Unsafe initContainer hacks

ARCHITECTURE OVERVIEW

MongoDB ReplicaSet (rs0)

mongo-0 → Primary (higher priority)
mongo-1 → Secondary
mongo-2 → Secondary

Components:

Headless Service: mongo.mongodb.svc.cluster.local

StatefulSet with persistent volumes

KeyFile-based internal auth

Bootstrap Job (one-time)

Backup & Restore scripts

PREREQUISITES

Kubernetes cluster (kubeadm / kind / k3s)

StorageClass available (local-path used)

kubectl configured

MongoDB image: mongo:6.0+

STEP 1 : CREATE NAMESPACE

kubectl create namespace mongodb

STEP 2 : CREATE MONGODB SECRETS (MANDATORY)

You already created this correctly:

kubectl create secret generic mongo-secret
--from-literal=MONGO_ROOT_USER=admin
--from-literal=MONGO_ROOT_PASSWORD=StrongPass123
--from-file=mongo-keyfile
-n mongodb

Purpose:

MONGO_ROOT_USER → MongoDB admin username

MONGO_ROOT_PASSWORD → MongoDB admin password

mongo-keyfile → Internal node authentication

IMPORTANT:

KeyFile permission must be 600

Handled automatically by initContainer

STEP 3 : CREATE HEADLESS SERVICE

kubectl apply -f headless-svc.yml

Purpose:

Provides stable DNS for StatefulSet pods

Required for MongoDB ReplicaSet discovery

Example DNS:

mongo-0.mongo.mongodb.svc.cluster.local

mongo-1.mongo.mongodb.svc.cluster.local

mongo-2.mongo.mongodb.svc.cluster.local

STEP 4 : APPLY RBAC (REQUIRED FOR JOBS)

kubectl apply -f sa.yml
kubectl apply -f role.yml
kubectl apply -f rolebinding.yml

Purpose:

Allows Jobs to:

List pods

Exec into MongoDB pods

Patch StatefulSet safely

STEP 5 : DEPLOY MONGODB STATEFULSET

kubectl apply -f sts.yml

What this does:

Deploys 3 MongoDB pods

Enables:

ReplicaSet (rs0)

Authentication

KeyFile security

Uses Persistent Volumes

Verify:
kubectl get pods -n mongodb

Wait until all pods are Running

STEP 6 : BOOTSTRAP REPLICASET & USERS (ONE TIME)

kubectl apply -f boot.yml

This Job automatically:

Initializes ReplicaSet

Sets member priorities

Creates admin user

Creates application users

This job runs once and can be deleted after success.

STEP 7 : VERIFY SETUP

Check ReplicaSet:

kubectl exec -it mongo-0 -n mongodb --
mongosh -u admin -p StrongPass123 --authenticationDatabase admin
--eval "rs.status()"

Check Primary:

kubectl exec -it mongo-0 -n mongodb --
mongosh -u admin -p StrongPass123 --authenticationDatabase admin
--eval "db.hello().isWritablePrimary"

BACKUP SCRIPT

Run:
./backup.sh

What it does:

Detects PRIMARY pod automatically

Runs mongodump

Creates compressed backup archive

RESTORE SCRIPT

Run:
./restore.sh

Why PRIMARY is required:

MongoDB allows writes only on PRIMARY

Restoring on secondary fails with:
"NotWritablePrimary"

CLEANUP (OPTIONAL)

kubectl delete namespace mongodb

BEST PRACTICES FOLLOWED

No manual MongoDB exec steps

No auth race conditions

Replica-safe automation

Kubernetes-native design

GitHub-ready production layout

AUTHOR

Aniket Bhagat
DevOps | Kubernetes | MongoDB | Cloud

====================================================================
