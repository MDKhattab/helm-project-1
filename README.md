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

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
------------------------** Dockerfile image **------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
*--------------- first stage----------------------*
FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Install envsubst
RUN apk add --no-cache gettext

*--------------- second stage----------------------*
FROM nginx:alpine

COPY --from=build /app/build /usr/share/nginx/html
# Copy template config (uses ${BACKEND_URL})
COPY default.conf.template /etc/nginx/templates/default.conf.template


EXPOSE 80

# Substitute BACKEND_URL into nginx config before starting
CMD ["/bin/sh", "-c", "envsubst '$BACKEND_URL' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'"]

******************************************************************************************
******************************************************************************************
******************************************************************************************

This Dockerfile is designed specifically to make your frontend image work correctly inside Kubernetes with Helm. Let me break down why each part is there and how it ties into the Helm project:

1. Multi‑stage build
FROM node:18-alpine AS build
...
RUN npm run build


- The first stage uses Node.js to install dependencies and build your React app into static files (/app/build).
- This keeps the final image small and efficient, because you don’t ship Node or dev dependencies into production.

2. Nginx runtime
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html


- The second stage uses Nginx to serve the static React build.
- This is the standard way to deploy React apps in Kubernetes: Nginx is lightweight, fast, and stable.

3. Dynamic backend configuration
# Copy template config (uses ${BACKEND_URL})
COPY default.conf.template /etc/nginx/templates/default.conf.template


- Instead of hard‑coding backend:8000 in nginx.conf, you copy a template that contains ${BACKEND_URL}.
- This allows the backend URL to be injected at runtime via environment variables.

4. envsubst at startup
CMD ["/bin/sh", "-c", "envsubst '$BACKEND_URL' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'"]


- envsubst replaces ${BACKEND_URL} in the template with the actual value from Kubernetes (http://learning-platform-backend-service:8000).
- This solves the problem you had earlier where nginx was crashing with host not found in upstream "backend".
- Now the frontend container dynamically adapts to whatever Service name/port Helm renders.

5. Why this matters for Helm
- Helm lets you define environment variables like:
env:
  - name: BACKEND_URL
    value: "http://{{ .Release.Name }}-backend-service:{{ .Values.service.backend.port }}"
- With this Dockerfile, that value is actually injected into nginx at runtime.
- Without envsubst, nginx would ignore the env var and keep using a static config, causing the CrashLoopBackOff you saw.

6. Benefits
- Portability: The same image works in different clusters or namespaces, because the backend URL is injected dynamically.
- Reproducibility: Helm templates control the Service names and ports, and the Dockerfile ensures nginx uses them.
- Stability: No more hard‑coded backend hostnames that break DNS resolution.

✅ In short: this Dockerfile makes your frontend image production‑ready for Kubernetes. It builds the React app, serves it with Nginx, and dynamically wires the frontend to the backend Service using Helm‑provided environment variables. That’s why it’s essential for your Helm project.


*********************************************************************************************************
*********************************************************************************************************
*********************************************************************************************************
what is envsubst ?
------------------

envsubst is a small utility that comes with the gettext package. Its job is to take a text file that contains environment variable placeholders (like ${BACKEND_URL}) and replace them with the actual values of those environment variables at runtime.

How it works
- Suppose you have a template file default.conf.template:
location /api {
    proxy_pass ${BACKEND_URL};
}
- If your container has an environment variable:
BACKEND_URL=http://learning-platform-backend-service:8000
- Running:
envsubst '$BACKEND_URL' < default.conf.template > default.conf


- will produce:
location /api {
    proxy_pass http://learning-platform-backend-service:8000;
}
Why it’s important in your Helm project- Dynamic configuration: Kubernetes Services get names like learning-platform-backend-service. You don’t want to hard‑code those into your Docker image.
- Helm templates: You set BACKEND_URL in your Deployment manifest. Helm renders the correct Service name and port.
- envsubst: At container startup, it rewrites nginx’s config file with the actual BACKEND_URL value. That way nginx proxies correctly to the backend without crashing.
Benefits- Flexibility: The same image works in different clusters, namespaces, or environments.
- Simplicity: No need to rebuild the Docker image when the backend URL changes — Kubernetes injects the env var, and envsubst updates the config.
- Reliability: Prevents the “host not found in upstream backend” error you saw earlier.
✅ In short: envsubst is the glue that lets your Helm chart inject environment variables into nginx’s config at runtime, making your frontend image portable and cluster‑aware

*************************************************************************************************
*************************************************************************************************

