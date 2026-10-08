# KIND Kubernetes Cluster on AWS EC2

This project creates a **3-node Kubernetes cluster using KIND (Kubernetes IN Docker)** on an **Ubuntu EC2 instance**.

## Architecture

```text
                    AWS EC2 Ubuntu
                         │
                    Docker Engine
                         │
                 ┌───────┴────────┐
                 │   KIND Cluster │
                 │                │
                 │ Control Plane  │
                 │      │         │
                 │  ┌───┴───┐     │
                 │  │       │     │
                 │Worker 1 Worker 2│
                 └────────┬────────┘
                          │
                    Kubernetes
```

## Project Structure

```text
kind-cluster/
│
├── install-kind.sh
├── kind-config.yaml
└── create-cluster.sh
```

### Files

| File                | Purpose                               |
| ------------------- | ------------------------------------- |
| `install-kind.sh`   | Installs Docker, Kind and kubectl     |
| `kind-config.yaml`  | Defines the 3-node Kubernetes cluster |
| `create-cluster.sh` | Creates and verifies the Kind cluster |

---

# 1. EC2 Prerequisites

Create an Ubuntu EC2 instance.

Make sure the EC2 Security Group allows:

| Protocol | Port | Purpose            |
| -------- | ---: | ------------------ |
| TCP      |   22 | SSH access         |
| TCP      | 8080 | Application access |

For testing, port `8080` can be opened to `0.0.0.0/0`. For real environments, restrict the source IP where possible.

> Port `30080` does **not** need to be opened in the EC2 Security Group because it is mapped internally to EC2 port `8080`.

---

# 2. Connect to EC2

SSH into the Ubuntu instance:

```bash
ssh -i <key.pem> ubuntu@<EC2-PUBLIC-IP>
```

Go to the project directory:

```bash
cd ~/kind-cluster
```

---

# 3. Make Scripts Executable

Run:

```bash
chmod +x install-kind.sh
chmod +x create-cluster.sh
```

Verify:

```bash
ls -l
```

---

# 4. Install Docker, KIND and kubectl

Run:

```bash
./install-kind.sh
```

The script installs:

```text
Docker
Kind
kubectl
```

It also:

* Starts Docker
* Enables Docker at boot
* Adds the Ubuntu user to the `docker` group
* Detects the system architecture
* Installs the appropriate Kind and kubectl binaries

---

# 5. Activate Docker Group

After installation, run:

```bash
newgrp docker
```

Verify Docker:

```bash
docker ps
```

Docker should work without `sudo`.

---

# 6. Create the KIND Cluster

Run:

```bash
./create-cluster.sh
```

The configuration creates:

```text
tws-cluster
│
├── Control Plane
├── Worker 1
└── Worker 2
```

---

# 7. Verify the Cluster

Check Kind:

```bash
kind get clusters
```

Expected:

```text
tws-cluster
```

Check Kubernetes nodes:

```bash
kubectl get nodes
```

You should see three nodes:

```text
control-plane
worker
worker2
```

Check cluster information:

```bash
kubectl cluster-info
```

Check all Pods:

```bash
kubectl get pods -A
```

---

# 8. Port Mapping

The `kind-config.yaml` contains:

```yaml
extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
    protocol: TCP
```

This creates the following mapping:

```text
Internet
   │
   │ :8080
   ▼
EC2 Ubuntu
   │
   │ :8080
   ▼
Kind Node
   │
   │ :30080
   ▼
Kubernetes Service
   │
   ▼
Application Pod
```

Therefore, when an application is exposed through Kubernetes NodePort `30080`, it can be accessed externally through:

```text
http://<EC2-PUBLIC-IP>:8080
```

---

# 9. Example NodePort Service

For an application exposed using NodePort:

```yaml
apiVersion: v1
kind: Service

metadata:
  name: my-app-service

spec:
  type: NodePort

  selector:
    app: my-app

  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

Apply it:

```bash
kubectl apply -f service.yaml
```

Then access:

```text
http://<EC2-PUBLIC-IP>:8080
```

---

# 10. Useful Commands

### Check nodes

```bash
kubectl get nodes
```

### Check Pods

```bash
kubectl get pods
```

### Check all namespaces

```bash
kubectl get pods -A
```

### Check Services

```bash
kubectl get svc
```

### Check deployments

```bash
kubectl get deployments
```

### Check Kind containers

```bash
docker ps
```

### Check Kind clusters

```bash
kind get clusters
```

---

# 11. Delete the Cluster

To delete the entire cluster:

```bash
kind delete cluster --name tws-cluster
```

Verify:

```bash
kind get clusters
```

The cluster should no longer be listed.

---

# 12. Important Notes

### KIND is mainly for learning/testing

KIND runs Kubernetes nodes as Docker containers:

```text
Docker
 ├── Kind Control Plane
 ├── Kind Worker 1
 └── Kind Worker 2
```

It is useful for:

* Kubernetes learning
* Local development
* Testing manifests
* CI environments
* Kubernetes experiments

It is **not normally used as a production Kubernetes platform**.

### Data persistence

KIND clusters are intended to be disposable. If you delete the cluster:

```bash
kind delete cluster --name tws-cluster
```

the Kubernetes resources inside that cluster are removed.

---

# Quick Start

For a fresh Ubuntu EC2 instance:

```bash
cd ~/kind-cluster

chmod +x install-kind.sh create-cluster.sh

./install-kind.sh

newgrp docker

./create-cluster.sh

kubectl get nodes
```

Expected result:

```text
NAME                     STATUS   ROLES
tws-cluster-control-plane Ready    control-plane
tws-cluster-worker        Ready    <none>
tws-cluster-worker2       Ready    <none>
```

The KIND Kubernetes cluster is now ready.
