# Simple Canary Deployment Example

This directory contains a simple canary deployment example using NGINX (stable version) and Apache (canary version) web servers. This example demonstrates canary deployment using the pod-based approach, where traffic distribution is controlled by the number of replicas.

## Overview

In this example:
- NGINX serves as the stable version (v1) with 4 replicas (80% of traffic)
- Apache serves as the canary version (v2) with 1 replica (20% of traffic)
- Both deployments are selected by the same service using the common label `app: web`
- Traffic is distributed proportionally to the number of pods

### Prerequisites to try this:

1. EC2 Instance with Ubuntu OS

2. Docker installed & Configured

3. Kind Installed

4. Kubectl Installed

5. Kind Cluster running(Use `kind-config.yml` file present in this directory.)

>   [!NOTE]
> 
>   You can create Kind Cluster using command: `kind create cluster --config kind-config.yml --name dep-strg`

---

## Files

- `namespace.yaml`: Creates a dedicated namespace for this example
- `nginx-deployment.yaml`: Deploys 4 replicas of NGINX (stable version)
- `apache-deployment.yaml`: Deploys 1 replica of Apache (canary version)
- `nginx-configmap.yaml`: ConfigMap with custom HTML for NGINX
- `apache-configmap.yaml`: ConfigMap with custom HTML for Apache
- `canary-service.yaml`: Service that selects both deployments
- `ingress.yaml`: Optional ingress for external access

## Setup Instructions

- Install the Ingress Controller for Kind

   ```bash
   # Apply the ingress controller manifest
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml

   # Wait for the ingress controller to be ready
   kubectl wait --namespace ingress-nginx \
   --for=condition=ready pod \
   --selector=app.kubernetes.io/component=controller \
   --timeout=120s
   ```

- If the ingress controller pod remains in Pending state due to node selector issues, remove the node selector:

   ```bash
   kubectl patch deployment ingress-nginx-controller -n ingress-nginx --type=json \
   -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector"}]'
   ```

- Varify Ingress-Controller is running or not using command:

  ```bash
  kubectl get pods -n ingress-nginx
  ```

  ![Screenshot 2025-05-30 122314](https://github.com/user-attachments/assets/d33a623f-5070-48fb-8ae5-ca12bf46d84e)


1. Create the namespace:
   ```bash
   kubectl apply -f namespace.yaml
   ```

2. Create the ConfigMaps:
   ```bash
   kubectl apply -f nginx-configmap.yaml
   kubectl apply -f apache-configmap.yaml
   ```

3. Deploy the applications:
   ```bash
   kubectl apply -f nginx-deployment.yaml
   kubectl apply -f apache-deployment.yaml
   ```

4. Create the service:
   ```bash
   kubectl apply -f canary-service.yaml
   ```

5. Create the ingress:
   ```bash
   kubectl apply -f ingress.yaml
   ```

## Testing the Canary Deployment

### 1: Using ingress

- Using the ingress controller:

   ```bash
   kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80 --address 0.0.0.0 &
   ```

Then access http://<Instance_Ip>:8080 multiple times, You should see:

   - NGINX (Version 1) approximately 80% of the time
   - Apache (Version 2) approximately 20% of the time

## Adjusting the Traffic Split

- To change the percentage of traffic going to each version, adjust the number of replicas:

   ```bash
   # Increase canary traffic to ~40% (3:2 ratio)
   kubectl scale deployment nginx-deployment -n simple-canary --replicas=3
   kubectl scale deployment apache-deployment -n simple-canary --replicas=2

   # Increase canary traffic to ~60% (2:3 ratio)
   kubectl scale deployment nginx-deployment -n simple-canary --replicas=2
   kubectl scale deployment apache-deployment -n simple-canary --replicas=3

   # Complete migration to canary version (0:5 ratio)
   kubectl scale deployment nginx-deployment -n simple-canary --replicas=0
   kubectl scale deployment apache-deployment -n simple-canary --replicas=5
   ```

## Cleanup

- Deleting Kind Cluster:

    ```bash
    kind delete cluster --name dep-strg
    ```

---

> [!Note]
>
> If you cannot access the web app after the update, check your terminal — you probably encountered an error like:
>
>   ```bash
>   error: lost connection to pod
>   ```
>
> Don’t worry! This happens because we’re running the cluster locally (e.g., with **Kind**), and the `kubectl port-forward` session breaks when the underlying pod is replaced during deployment (especially with `Recreate` strategy).
>
> 🔁 Just run the `kubectl port-forward` command again to re-establish the connection and access the app in your browser.
>
> ✅ This issue won't occur when deploying on managed Kubernetes services like **AWS EKS**, **GKE**, or **AKS**, because in those environments you usually expose services using `NodePort`, `LoadBalancer`, or Ingress — not `kubectl port-forward`.