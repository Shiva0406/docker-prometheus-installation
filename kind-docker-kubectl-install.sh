#!/bin/bash

# ============================================================
# KIND KUBERNETES ENVIRONMENT SETUP
# ============================================================
# Installs:
#   1. Docker
#   2. Kind
#   3. kubectl
#
# Target:
#   Ubuntu Linux / EC2
# ============================================================

set -e
set -o pipefail

echo "============================================================"
echo "🚀 Starting Docker, Kind and kubectl installation"
echo "============================================================"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

KIND_VERSION="v0.33.0"

# ------------------------------------------------------------
# Check OS
# ------------------------------------------------------------

if [ ! -f /etc/os-release ]; then
    echo "❌ Cannot determine Linux distribution."
    exit 1
fi

source /etc/os-release

if [ "$ID" != "ubuntu" ]; then
    echo "⚠️ This script is designed for Ubuntu."
    echo "Detected OS: $ID"
    exit 1
fi

echo "✅ Ubuntu detected: $VERSION_ID"

# ------------------------------------------------------------
# Determine actual user
# ------------------------------------------------------------

if [ "$(id -u)" -eq 0 ]; then
    TARGET_USER="${SUDO_USER:-root}"
else
    TARGET_USER="$USER"
fi

echo "👤 Target user: $TARGET_USER"

# ------------------------------------------------------------
# 1. Install required packages
# ------------------------------------------------------------

echo
echo "📦 Installing required packages..."

sudo apt-get update -y

sudo apt-get install -y \
    curl \
    ca-certificates \
    docker.io

echo "✅ Required packages installed."

# ------------------------------------------------------------
# 2. Start and enable Docker
# ------------------------------------------------------------

echo
echo "🐳 Starting Docker..."

sudo systemctl enable --now docker

if sudo systemctl is-active --quiet docker; then
    echo "✅ Docker service is running."
else
    echo "❌ Docker service failed to start."
    exit 1
fi

# ------------------------------------------------------------
# 3. Add user to Docker group
# ------------------------------------------------------------

echo
echo "👤 Configuring Docker group..."

if [ "$TARGET_USER" != "root" ]; then

    sudo usermod -aG docker "$TARGET_USER"

    echo "✅ $TARGET_USER added to docker group."

else

    echo "⚠️ Running as root. Docker group modification skipped."

fi

# ------------------------------------------------------------
# 4. Install Kind
# ------------------------------------------------------------

echo
echo "📦 Installing Kind..."

if command -v kind >/dev/null 2>&1; then

    echo "✅ Kind is already installed."

    kind --version

else

    ARCH=$(uname -m)

    case "$ARCH" in

        x86_64)
            KIND_ARCH="amd64"
            ;;

        aarch64|arm64)
            KIND_ARCH="arm64"
            ;;

        *)
            echo "❌ Unsupported architecture: $ARCH"
            exit 1
            ;;

    esac

    echo "Architecture detected: $ARCH"
    echo "Downloading Kind ${KIND_VERSION}..."

    curl -fL -o /tmp/kind \
        "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${KIND_ARCH}"

    chmod +x /tmp/kind

    sudo install -m 0755 /tmp/kind /usr/local/bin/kind

    rm -f /tmp/kind

    echo "✅ Kind installed successfully."

fi

# ------------------------------------------------------------
# 5. Install kubectl
# ------------------------------------------------------------

echo
echo "📦 Installing kubectl..."

if command -v kubectl >/dev/null 2>&1; then

    echo "✅ kubectl is already installed."

else

    ARCH=$(uname -m)

    case "$ARCH" in

        x86_64)
            KUBECTL_ARCH="amd64"
            ;;

        aarch64|arm64)
            KUBECTL_ARCH="arm64"
            ;;

        *)
            echo "❌ Unsupported architecture: $ARCH"
            exit 1
            ;;

    esac

    KUBECTL_VERSION=$(curl -fsSL \
        https://dl.k8s.io/release/stable.txt)

    echo "Latest stable kubectl: ${KUBECTL_VERSION}"

    curl -fL -o /tmp/kubectl \
        "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"

    chmod +x /tmp/kubectl

    sudo install -o root -g root -m 0755 \
        /tmp/kubectl /usr/local/bin/kubectl

    rm -f /tmp/kubectl

    echo "✅ kubectl installed successfully."

fi

# ------------------------------------------------------------
# 6. Display versions
# ------------------------------------------------------------

echo
echo "============================================================"
echo "🔍 Installed Versions"
echo "============================================================"

echo
echo "Docker:"
docker --version

echo
echo "Kind:"
kind --version

echo
echo "kubectl:"
kubectl version --client

echo
echo "============================================================"
echo "🎉 Installation completed successfully!"
echo "============================================================"

echo
echo "⚠️ IMPORTANT:"
echo "If this is the first time the user was added to the"
echo "docker group, run:"
echo
echo "    newgrp docker"
echo
echo "or logout/login before using Docker without sudo."

echo
echo "Next step:"
echo
echo "    kind create cluster"
echo
