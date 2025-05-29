# Canary Deployment with Ingress in Kubernetes

This guide explains how to implement a canary deployment strategy using Kubernetes Ingress in a Kind cluster.

## What is Canary Deployment with Ingress?

Canary deployment with Ingress allows you to route a percentage of traffic to a new version of your application while keeping the majority of traffic going to the stable version. This is achieved using Ingress annotations that control traffic splitting.

## Prerequisites

- Kind cluster running
- kubectl installed

## Setup Steps

### 1. Install the Ingress Controller

```bash
kubectl apply -f ingress-controller.yaml
```

### 2. Create the namespace

```bash
kubectl apply -f canary-namespace.yml
```

### 3. Deploy the stable version (v1)

```bash
kubectl apply -f canary-v1-deployment.yaml
kubectl apply -f service-v1.yaml
```

### 4. Deploy the main ingress for the stable version

```bash
kubectl apply -f main-ingress.yaml
```

### 5. Deploy the canary version (v2)

```bash
kubectl apply -f canary-v2-deployment.yaml
kubectl apply -f service-v2.yaml
```

### 6. Deploy the canary ingress

```bash
kubectl apply -f canary-ingress.yaml
```

## How it works

1. The main ingress routes all traffic to the v1 service by default
2. The canary ingress has annotations that tell the ingress controller to route a percentage of traffic to v2:
   - `nginx.ingress.kubernetes.io/canary: "true"` - Marks this ingress as a canary
   - `nginx.ingress.kubernetes.io/canary-weight: "20"` - Routes 20% of traffic to v2

## Testing the Canary Deployment

Access the application using your EC2 instance IP:
```
http://54.85.89.218:30080
```

Refresh multiple times - you should see the v1 version (without footer) approximately 80% of the time and the v2 version (with footer) approximately 20% of the time.

## Adjusting the Canary Weight

To change the percentage of traffic going to the canary version:

1. Edit the canary-ingress.yaml file and change the canary-weight annotation
2. Apply the updated ingress:
   ```bash
   kubectl apply -f canary-ingress.yaml
   ```

## Gradual Rollout Example

1. Start with 20% traffic to v2:
   ```
   nginx.ingress.kubernetes.io/canary-weight: "20"
   ```

2. Increase to 50% traffic to v2:
   ```
   nginx.ingress.kubernetes.io/canary-weight: "50"
   ```

3. Complete the rollout (100% traffic to v2):
   - Option 1: Set canary weight to 100
   - Option 2: Update the main ingress to point to v2 and remove the canary ingress

## Monitoring

Monitor your deployments during the canary process:

```bash
kubectl get pods -n canary-ns
kubectl get ingress -n canary-ns
```

## Cleanup

```bash
kubectl delete namespace canary-ns
kubectl delete -f ingress-controller.yaml
```
