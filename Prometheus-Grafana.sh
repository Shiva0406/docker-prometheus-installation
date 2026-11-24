
#!/bin/bash

# ==============================================================
# PROJECT: Prometheus + Grafana Installation
# PLATFORM: AWS EC2 Ubuntu Linux
# KUBERNETES: Kind Cluster
# INSTALLATION: Helm
# NAMESPACE: monitoring
# ==============================================================

set -Eeuo pipefail

# ---------------- CONFIGURATION ----------------

NAMESPACE="monitoring"
RELEASE_NAME="kube-prometheus-stack"
REPO_NAME="prometheus-community"
REPO_URL="https://prometheus-community.github.io/helm-charts"
CHART_NAME="${REPO_NAME}/kube-prometheus-stack"

# Lab password only. Change this before installation.
GRAFANA_ADMIN_USER="admin"
GRAFANA_ADMIN_PASSWORD="ChangeMe-Admin-2026!"

# ---------------- ERROR HANDLER ----------------

error_handler() {
    echo ""
    echo "ERROR: Installation failed at line $1"
    echo "Check the Helm and Kubernetes logs."
    exit 1
}

trap 'error_handler $LINENO' ERR

# ---------------- START ----------------

echo ""
echo "=================================================="
echo " PROMETHEUS + GRAFANA INSTALLATION"
echo "=================================================="

# 1. Check required commands

echo ""
echo "[1/8] Checking prerequisites..."

for cmd in kubectl helm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: $cmd is not installed."
        exit 1
    fi
done

echo "kubectl: $(kubectl version --client -o yaml | grep gitVersion | head -1)"
echo "Helm: $(helm version --short)"

# 2. Check Kubernetes connection

echo ""
echo "[2/8] Checking Kubernetes cluster..."

kubectl cluster-info

CURRENT_CONTEXT=$(kubectl config current-context)

echo "Current context: $CURRENT_CONTEXT"

if ! kubectl get nodes >/dev/null 2>&1; then
    echo "ERROR: Kubernetes cluster is not accessible."
    exit 1
fi

kubectl get nodes

# 3. Add Helm repository

echo ""
echo "[3/8] Adding Prometheus Helm repository..."

if ! helm repo list | grep -q "^${REPO_NAME}[[:space:]]"; then
    helm repo add "$REPO_NAME" "$REPO_URL"
else
    echo "Prometheus repository already exists."
fi

helm repo update

# 4. Create monitoring namespace

echo ""
echo "[4/8] Creating monitoring namespace..."

kubectl create namespace "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# 5. Install Prometheus and Grafana

echo ""
echo "[5/8] Installing Prometheus and Grafana using Helm..."

helm upgrade --install "$RELEASE_NAME" "$CHART_NAME" \
    --namespace "$NAMESPACE" \
    --set grafana.enabled=true \
    --set grafana.adminUser="$GRAFANA_ADMIN_USER" \
    --set grafana.adminPassword="$GRAFANA_ADMIN_PASSWORD" \
    --set grafana.persistence.enabled=false \
    --set prometheus.prometheusSpec.retention=7d \
    --set alertmanager.enabled=true \
    --wait \
    --timeout 20m

# 6. Wait for deployments and pods

echo ""
echo "[6/8] Waiting for monitoring workloads..."

kubectl get pods -n "$NAMESPACE"

kubectl wait \
    --namespace "$NAMESPACE" \
    --for=condition=Ready pod \
    --all \
    --timeout=600s

# 7. Verify installation

echo ""
echo "[7/8] Verifying installation..."

echo ""
echo "========== HELM RELEASE =========="

helm list -n "$NAMESPACE"

echo ""
echo "========== POD STATUS =========="

kubectl get pods -n "$NAMESPACE" -o wide

echo ""
echo "========== SERVICES =========="

kubectl get svc -n "$NAMESPACE"

echo ""
echo "========== STORAGE =========="

kubectl get pvc -n "$NAMESPACE"

# 8. Display access instructions

echo ""
echo "[8/8] Installation completed!"

echo ""
echo "=================================================="
echo " PROMETHEUS + GRAFANA DETAILS"
echo "=================================================="

echo ""
echo "Namespace: $NAMESPACE"
echo "Helm Release: $RELEASE_NAME"

echo ""
echo "Grafana Credentials:"
echo "Username: $GRAFANA_ADMIN_USER"
echo "Password: $GRAFANA_ADMIN_PASSWORD"

echo ""
echo "Grafana Port Forward:"
echo "kubectl port-forward -n $NAMESPACE svc/${RELEASE_NAME}-grafana 3000:80"

echo ""
echo "Prometheus Port Forward:"
echo "kubectl port-forward -n $NAMESPACE svc/${RELEASE_NAME}-prometheus 9090:9090"

echo ""
echo "Access URLs through an SSH tunnel:"
echo "Grafana:    http://localhost:3000"
echo "Prometheus: http://localhost:9090"

echo ""
echo "=================================================="
echo " INSTALLATION SCRIPT FINISHED"
echo "=================================================="

