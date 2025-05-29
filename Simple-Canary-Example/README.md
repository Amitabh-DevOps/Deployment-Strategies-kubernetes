# Simple Canary Deployment Example

This directory contains a simple canary deployment example using NGINX (stable version) and Apache (canary version) web servers. This example demonstrates canary deployment using the pod-based approach, where traffic distribution is controlled by the number of replicas.

## Overview

In this example:
- NGINX serves as the stable version (v1) with 4 replicas (80% of traffic)
- Apache serves as the canary version (v2) with 1 replica (20% of traffic)
- Both deployments are selected by the same service using the common label `app: web`
- Traffic is distributed proportionally to the number of pods

## Prerequisites

- Kubernetes cluster (Kind, Minikube, or any other)
- kubectl installed and configured

## Files

- `namespace.yaml`: Creates a dedicated namespace for this example
- `nginx-deployment.yaml`: Deploys 4 replicas of NGINX (stable version)
- `apache-deployment.yaml`: Deploys 1 replica of Apache (canary version)
- `nginx-configmap.yaml`: ConfigMap with custom HTML for NGINX
- `apache-configmap.yaml`: ConfigMap with custom HTML for Apache
- `canary-service.yaml`: Service that selects both deployments
- `ingress.yaml`: Optional ingress for external access

## Setup Instructions

### Install the Ingress Controller for Kind

```bash
# Apply the ingress controller manifest
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml

# Wait for the ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

If the ingress controller pod remains in Pending state due to node selector issues, remove the node selector:

```bash
kubectl patch deployment ingress-nginx-controller -n ingress-nginx --type=json \
  -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector"}]'
```

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

5. (Optional) Create the ingress:
   ```bash
   kubectl apply -f ingress.yaml
   ```

## Testing the Canary Deployment

Then access http://localhost:8080 multiple times. You should see:
- NGINX (Version 1) approximately 80% of the time
- Apache (Version 2) approximately 20% of the time

### 1: Using ingress

If you've set up the ingress controller:

```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80 --address 0.0.0.0 &
```

Then access http://<Instance_Ip>:8080 multiple times.

## Adjusting the Traffic Split

To change the percentage of traffic going to each version, adjust the number of replicas:

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

```bash
kubectl delete namespace simple-canary
```

## Why This Approach Works

This approach works because:

1. The Kubernetes service routes traffic randomly to pods that match its selector
2. With 4 NGINX pods and 1 Apache pod, approximately 80% of requests go to NGINX and 20% to Apache
3. By adjusting the number of pods, you can control the traffic distribution
4. This approach is simple and doesn't require special ingress controllers or service mesh

## Advantages of This Approach

- Simple to implement
- Works in any Kubernetes cluster
- No special controllers or add-ons required
- Easy to understand and visualize
- Straightforward scaling to adjust traffic

## Limitations

- Less precise control over traffic percentages
- Traffic distribution depends on pod availability and readiness
- No header-based or cookie-based routing
- No advanced traffic shaping capabilities

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