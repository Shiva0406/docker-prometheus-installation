#!/bin/bash

# ============================================================
# Helm Installation Script
# OS: Ubuntu / Debian-based Linux
# Purpose: Install Helm 3
# ============================================================

set -e

echo "============================================================"
echo " Installing Helm"
echo "============================================================"

# ------------------------------------------------------------
# 1. Check whether Helm is already installed
# ------------------------------------------------------------

if command -v helm >/dev/null 2>&1; then
    echo "Helm is already installed."
    helm version
    exit 0
fi

# ------------------------------------------------------------
# 2. Check whether curl is installed
# ------------------------------------------------------------

if ! command -v curl >/dev/null 2>&1; then
    echo "curl is not installed."
    echo "Installing curl..."

    sudo apt-get update
    sudo apt-get install -y curl
fi

# ------------------------------------------------------------
# 3. Download and run the official Helm installer
# ------------------------------------------------------------

echo "Downloading Helm installation script..."

curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    -o /tmp/get_helm.sh

# Make the script executable
chmod +x /tmp/get_helm.sh

# Run Helm installer
/tmp/get_helm.sh

# ------------------------------------------------------------
# 4. Verify installation
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo " Helm Installation Completed"
echo "============================================================"

helm version

echo ""
echo "Helm location:"
which helm

echo ""
echo "Helm installation successful!"