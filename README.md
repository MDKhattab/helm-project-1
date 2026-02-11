Here’s a complete README.md file you can drop straight into your Helm project repository:
# Learning Platform Helm Project

This Helm chart deploys a **Learning Platform** application on Kubernetes.  
The stack includes:
- **Frontend** (React built and served with Nginx)
- **Backend** (Node.js/Express API)
- **Postgres** (database)

---

## Prerequisites

- Kubernetes cluster (tested with Minikube)
- Helm v3+
- Docker registry access (with a secret for pulling private images)
- kubectl configured to access your cluster

---

## Project Structure

- **helm-project/** – Helm templates for frontend, backend, and Postgres
- **values.yaml** – Default configuration values
- **Dockerfiles** – Multi-stage builds for frontend and backend
- **default.conf.template** – Nginx config template with `envsubst` support

---

## Installation

1. **Build and push images**
   ```bash
   docker build -t <registry>/project:frontendv1.0 ./frontend
   docker build -t <registry>/project:backendv1.0 ./backend
   docker push <registry>/project:frontendv1.0
   docker push <registry>/project:backendv1.0


- Create Docker registry secret
kubectl create secret docker-registry regcred \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email>
- Install Helm chart
helm install learning-platform ./helm-project


- Upgrade (after changes)
helm upgrade learning-platform ./helm-project



Services
|  |  |  |  | 
| learning-platform-frontend |  |  |  | 
| learning-platform-backend |  |  |  | 
| learning-platform-postgres |  |  |  | 



Local Access with Minikube
Since Services are ClusterIP by default, use Minikube tunnel:
minikube service learning-platform-frontend-service


This will expose the frontend at a local URL (e.g., http://127.0.0.1:34915).
For easier access, you can change the Service type to NodePort in values.yaml:
service:
  frontend:
    type: NodePort
    port: 3000
    targetPort: 3000
    nodePort: 30080


Then access at http://127.0.0.1:30080.

Environment Variables
- Frontend
- BACKEND_URL=http://learning-platform-backend-service:8000
- Backend
- DB_HOST=learning-platform-postgres-service
- DB_PORT=5432
These are injected via ConfigMaps and Helm templates.

Troubleshooting
- Frontend CrashLoopBackOff
Ensure default.conf.template uses ${BACKEND_URL} and the Dockerfile runs envsubst.
- Backend stuck in Init
Verify DB_HOST matches the Postgres Service name and the Service selector matches pod labels.
- Postgres Pending
Check PVC binding and StorageClass configuration.

Cleanup
To remove all resources:
helm uninstall learning-platform
kubectl delete pvc -l app=learning-platform-postgres



Architecture Diagram
graph TD
    A[Frontend (Nginx)] -->|HTTP| B[Backend (Node.js)]
    B -->|SQL| C[Postgres Database]



Notes
- This chart is designed for local development and testing.
- For production, consider using LoadBalancer or Ingress for frontend exposure, and configure persistent storage for Postgres.

---

