```bash
#!/bin/bash

# ============================================================
# NGINX DEPLOYMENT ON KIND KUBERNETES
# ============================================================

set -e
set -o pipefail

echo "============================================================"
echo "🚀 Deploying NGINX on Kubernetes"
echo "============================================================"

# ------------------------------------------------------------
# Check kubectl
# ------------------------------------------------------------

if ! command -v kubectl >/dev/null 2>&1; then
    echo "❌ kubectl is not installed."
    exit 1
fi

echo "✅ kubectl found."

# ------------------------------------------------------------
# Check Kind cluster
# ------------------------------------------------------------

if ! command -v kind >/dev/null 2>&1; then
    echo "❌ Kind is not installed."
    exit 1
fi

if ! kind get clusters | grep -Fxq "tws-cluster"; then
    echo "❌ Kind cluster 'tws-cluster' does not exist."
    echo "Run ./create-cluster.sh first."
    exit 1
fi

echo "✅ Kind cluster found."

# ------------------------------------------------------------
# Check Kubernetes nodes
# ------------------------------------------------------------

echo
echo "🔍 Kubernetes nodes:"
kubectl get nodes

# ------------------------------------------------------------
# Create NGINX Deployment
# ------------------------------------------------------------

echo
echo "📦 Creating NGINX deployment..."

kubectl create deployment nginx \
    --image=nginx:latest \
    --replicas=1 \
    --dry-run=client -o yaml | kubectl apply -f -

echo "✅ NGINX deployment created."

# ------------------------------------------------------------
# Expose NGINX using NodePort
# ------------------------------------------------------------

echo
echo "🌐 Creating NGINX service..."

kubectl expose deployment nginx \
    --type=NodePort \
    --port=80 \
    --target-port=80 \
    --dry-run=client -o yaml | kubectl apply -f -

# ------------------------------------------------------------
# Set NodePort to 30080
# ------------------------------------------------------------

echo
echo "🔧 Configuring NodePort 30080..."

kubectl patch service nginx \
    -p '{"spec":{"ports":[{"port":80,"targetPort":80,"nodePort":30080}]}}'

echo "✅ NGINX exposed on NodePort 30080."

# ------------------------------------------------------------
# Wait for NGINX pod
# ------------------------------------------------------------

echo
echo "⏳ Waiting for NGINX pod..."

kubectl rollout status deployment/nginx --timeout=120s

# ------------------------------------------------------------
# Verification
# ------------------------------------------------------------

echo
echo "============================================================"
echo "🔍 NGINX VERIFICATION"
echo "============================================================"

echo
echo "Deployment:"
kubectl get deployment nginx

echo
echo "Pod:"
kubectl get pods -l app=nginx -o wide

echo
echo "Service:"
kubectl get service nginx

echo
echo "============================================================"
echo "🎉 NGINX DEPLOYMENT COMPLETED"
echo "============================================================"

echo
echo "NGINX should be accessible through:"
echo
echo "http://<EC2-PUBLIC-IP>:8080"
echo
echo "EC2 port 8080 -> Kind port 30080 -> NGINX service -> NGINX pod"
echo
```
