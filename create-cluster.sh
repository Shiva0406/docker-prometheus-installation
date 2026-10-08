#!/bin/bash

# ============================================================
# KIND CLUSTER CREATION SCRIPT
# ============================================================

set -e
set -o pipefail

CLUSTER_NAME="tws-cluster"
CONFIG_FILE="kind-config.yaml"

echo "============================================================"
echo "🚀 Creating KIND Kubernetes Cluster"
echo "============================================================"

# ------------------------------------------------------------
# Check Kind
# ------------------------------------------------------------

if ! command -v kind >/dev/null 2>&1; then
    echo "❌ Kind is not installed."
    echo "Run ./install-kind.sh first."
    exit 1
fi

echo "✅ Kind is installed."

# ------------------------------------------------------------
# Check kubectl
# ------------------------------------------------------------

if ! command -v kubectl >/dev/null 2>&1; then
    echo "❌ kubectl is not installed."
    echo "Run ./install-kind.sh first."
    exit 1
fi

echo "✅ kubectl is installed."

# ------------------------------------------------------------
# Check Docker
# ------------------------------------------------------------

if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not accessible."
    echo
    echo "Run:"
    echo "    newgrp docker"
    echo
    exit 1
fi

echo "✅ Docker is accessible."

# ------------------------------------------------------------
# Check configuration file
# ------------------------------------------------------------

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ $CONFIG_FILE not found."
    echo
    echo "Make sure kind-config.yaml is in the same directory."
    exit 1
fi

echo "✅ $CONFIG_FILE found."

# ------------------------------------------------------------
# Check existing cluster
# ------------------------------------------------------------

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then

    echo
    echo "⚠️ Cluster '$CLUSTER_NAME' already exists."
    echo
    echo "Existing clusters:"
    kind get clusters

else

    # --------------------------------------------------------
    # Create cluster
    # --------------------------------------------------------

    echo
    echo "🚀 Creating cluster..."
    echo

    kind create cluster \
        --name "$CLUSTER_NAME" \
        --config "$CONFIG_FILE"

    echo
    echo "✅ Cluster created successfully."

fi

# ------------------------------------------------------------
# Verify cluster
# ------------------------------------------------------------

echo
echo "============================================================"
echo "🔍 Cluster Verification"
echo "============================================================"

echo
echo "Kind clusters:"
kind get clusters

echo
echo "Kubernetes nodes:"
kubectl get nodes -o wide

echo
echo "Cluster information:"
kubectl cluster-info

echo
echo "============================================================"
echo "🎉 KIND CLUSTER IS READY"
echo "============================================================"