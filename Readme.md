# MongoDB Replica Set on Kubernetes (Production-Ready)

This repository provides a **production-grade MongoDB Replica Set deployment on Kubernetes** using **StatefulSets**, **Headless Services**, and a **bootstrap Job** to automate:

- Replica Set initialization
- Primary election with priority
- Admin and application user creation
- Secure, repeatable cluster setup

---

## 🏗️ Architecture Overview

- **Kubernetes StatefulSet** for stable pod identities
- **Headless Service** for stable DNS
- **3-member MongoDB Replica Set**
- **Bootstrap Job** (one-time) to:
  - Initialize replica set
  - Create admin and application users
- Authentication enabled using MongoDB users
- Ready for backup, restore, and scaling

