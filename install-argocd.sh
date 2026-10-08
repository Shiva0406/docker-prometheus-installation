#!/bin/bash

# ============================================================
# Argo CD Installation Script
# Purpose : Install Argo CD on Kubernetes
# OS      : Linux
# Requires: kubectl + running Kubernetes cluster
# ============================================================

set -e

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

ARGOCD_NAMESPACE="argocd"

echo "============================================================"
echo "        Argo CD Installation"
echo "============================================================"

# ------------------------------------------------------------
# 1. Check kubectl
# ------------------------------------------------------------

echo ""
echo "[1/6] Checking kubectl..."

if ! command -v kubectl >/dev/null 2>&1; then
    echo "ERROR: kubectl is not installed."
    echo "Please install kubectl first."
    exit 1
fi

echo "kubectl found:"
kubectl version --client

# ------------------------------------------------------------
# 2. Check Kubernetes cluster
# ------------------------------------------------------------

echo ""
echo "[2/6] Checking Kubernetes cluster..."

if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "ERROR: Kubernetes cluster is not reachable."
    echo "Check your kubeconfig and cluster."
    exit 1
fi

echo "Kubernetes cluster is reachable."

kubectl get nodes

# ------------------------------------------------------------
# 3. Create Argo CD namespace
# ------------------------------------------------------------

echo ""
echo "[3/6] Creating Argo CD namespace..."

kubectl get namespace "$ARGOCD_NAMESPACE" >/dev/null 2>&1 || \
kubectl create namespace "$ARGOCD_NAMESPACE"

echo "Namespace '$ARGOCD_NAMESPACE' is ready."

# ------------------------------------------------------------
# 4. Install Argo CD
# ------------------------------------------------------------

echo ""
echo "[4/6] Installing Argo CD..."

kubectl apply \
    -n "$ARGOCD_NAMESPACE" \
    --server-side \
    --force-conflicts \
    -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ------------------------------------------------------------
# 5. Wait for Argo CD components
# ------------------------------------------------------------

echo ""
echo "[5/6] Waiting for Argo CD components..."

kubectl wait \
    --for=condition=Available \
    deployment/argocd-server \
    -n "$ARGOCD_NAMESPACE" \
    --timeout=300s

echo "Argo CD server is ready."

# ------------------------------------------------------------
# 6. Show installation status
# ------------------------------------------------------------

echo ""
echo "[6/6] Argo CD installation completed."

echo ""
echo "============================================================"
echo " Argo CD Pods"
echo "============================================================"

kubectl get pods -n "$ARGOCD_NAMESPACE"

echo ""
echo "============================================================"
echo " Argo CD Services"
echo "============================================================"

kubectl get svc -n "$ARGOCD_NAMESPACE"

echo ""
echo "============================================================"
echo " Argo CD Installation Successful!"
echo "============================================================"

echo ""
echo "Namespace:"
echo "  $ARGOCD_NAMESPACE"

echo ""
echo "Next step:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"

echo ""
echo "Then open:"
echo "  https://localhost:8080"

echo ""
echo "To get the initial admin password:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret \\"
echo "    -o jsonpath=\"{.data.password}\" | base64 -d"
echo ""