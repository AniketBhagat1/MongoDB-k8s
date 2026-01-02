MongoDB ReplicaSet on Kubernetes (Secured & Automated)
Purpose

This repository provides a production-safe MongoDB ReplicaSet deployment on Kubernetes with:

✅ 3-node MongoDB ReplicaSet

✅ Internal authentication using keyFile

✅ Admin & application user creation

✅ Headless service for stable DNS

✅ Automated replica-set initialization

✅ Backup & restore scripts

✅ RBAC-based Kubernetes access

This setup avoids unsafe patterns like:

Enabling auth before user creation

Manual kubectl exec steps

Non-deterministic primary election

Architecture Overview
MongoDB ReplicaSet (rs0)
│
├── mongo-0 (Primary – higher priority)
├── mongo-1 (Secondary)
├── mongo-2 (Secondary)
│
├── Headless Service (mongo.mongodb.svc.cluster.local)
├── KeyFile-based internal authentication
├── Admin + DB users auto-created
└── Backup & Restore via mongodump / mongorestore

Prerequisites

Kubernetes cluster (tested on kubeadm)

StorageClass available (local-path used here)

kubectl configured

MongoDB image: mongo:6.0

Namespace Creation
kubectl create namespace mongodb

Step 1️⃣ Create MongoDB Secrets (MANDATORY)

You already created this correctly:

kubectl create secret generic mongo-secret \
  --from-literal=MONGO_ROOT_USER=admin \
  --from-literal=MONGO_ROOT_PASSWORD=StrongPass123 \
  --from-file=mongo-keyfile \
  -n mongodb

Purpose

MONGO_ROOT_USER → admin username

MONGO_ROOT_PASSWORD → admin password

mongo-keyfile → internal node-to-node authentication

⚠️ KeyFile must have chmod 600 (handled in initContainer).

Step 2️⃣ Create Headless Service
kubectl apply -f headless-svc.yml

Purpose

Enables stable DNS:

mongo-0.mongo.mongodb.svc.cluster.local

mongo-1.mongo.mongodb.svc.cluster.local

Required for ReplicaSet discovery

Step 3️⃣ Create RBAC (Required for Jobs)
kubectl apply -f sa.yml
kubectl apply -f role.yml
kubectl apply -f rolebinding.yml

Purpose

Allows bootstrap and auth jobs to:

Read pods

Exec into MongoDB pods

Patch StatefulSets

Step 4️⃣ Deploy MongoDB StatefulSet
kubectl apply -f sts.yml

Purpose

Deploys 3 MongoDB pods

Starts MongoDB with:

--replSet rs0

--auth

--keyFile

Persistent storage via PVC

Verify Pods
kubectl get pods -n mongodb


Wait until all pods are Running.

Step 5️⃣ Bootstrap ReplicaSet & Users (ONE-TIME)
kubectl apply -f boot.yml

What This Job Does

✔ Initializes ReplicaSet
✔ Sets member priorities
✔ Creates:

Admin user

Application users

Database roles

This job runs only once and is idempotent-safe.

Step 6️⃣ Enable Authentication (If using auth.yml)
kubectl apply -f auth.yml

Purpose

Ensures MongoDB runs with authentication permanently

Restarts StatefulSet safely

Verification Steps
Check ReplicaSet Status
kubectl exec -it mongo-0 -n mongodb -- \
mongosh -u admin -p StrongPass123 --authenticationDatabase admin \
--eval "rs.status()"

Identify Primary
kubectl exec -it mongo-0 -n mongodb -- \
mongosh -u admin -p StrongPass123 --authenticationDatabase admin \
--eval "db.hello().isWritablePrimary"

Backup Script
./backup.sh

Purpose

Automatically detects PRIMARY

Uses mongodump

Stores compressed backups

Restore Script
./restore.sh

Purpose

Restores data only to PRIMARY

Ensures write consistency

Uses mongorestore

Why Restore Must Target Primary

MongoDB blocks writes on secondaries.

Attempting restore on a secondary results in:

NotWritablePrimary


Hence restore scripts must always detect the primary pod.

Cleanup (Optional)
kubectl delete namespace mongodb

Best Practices Followed

✔ No manual kubectl exec needed
✔ No auth lockout risk
✔ Replica-safe initialization
✔ Kubernetes-native automation
✔ GitHub-ready production layout

Author

Aniket Bhagat
DevOps | Kubernetes | MongoDB | Cloud
