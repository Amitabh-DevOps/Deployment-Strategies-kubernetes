# Canary Deployment with NodePort Services in Kubernetes

This guide explains how to implement a canary deployment strategy using Kubernetes NodePort services in a Kind cluster.

## What is Canary Deployment?

Canary deployment is a strategy where a new version of an application is gradually rolled out to a subset of users before making it available to everyone. This helps identify potential issues before they affect all users.

## Prerequisites

- Kind cluster running
- kubectl installed

## Setup Steps

### 1. Create the namespace

```bash
kubectl apply -f canary-namespace.yml
```

### 2. Deploy the stable version (v1)

```bash
kubectl apply -f canary-v1-deployment.yaml
kubectl apply -f service-v1.yaml
```

### 3. Deploy the canary version (v2)

```bash
kubectl apply -f canary-v2-deployment.yaml
kubectl apply -f service-v2.yaml
```

## How it works

1. The stable version (v1) is deployed with 4 replicas and exposed on NodePort 30081
2. The canary version (v2) is deployed with 1 replica and exposed on NodePort 30082
3. Users can access:
   - Stable version (v1): http://54.85.89.218:30081
   - Canary version (v2): http://54.85.89.218:30082

## Testing the Canary Deployment

1. Access the stable version:
   ```
   http://54.85.89.218:30081
   ```
   You should see the version without footer.

2. Access the canary version:
   ```
   http://54.85.89.218:30082
   ```
   You should see the version with footer.

## Gradual Rollout Process

1. Start with minimal canary traffic (1 replica for v2, 4 replicas for v1)
2. Monitor the canary version for issues
3. Gradually increase canary traffic by scaling up v2 and scaling down v1:

   ```bash
   # Increase canary version (v2) to 2 replicas
   kubectl scale deployment online-shop-v2 -n canary-ns --replicas=2
   
   # Decrease stable version (v1) to 3 replicas
   kubectl scale deployment online-shop-v1 -n canary-ns --replicas=3
   ```

4. Continue the gradual rollout until complete:
   ```bash
   # Complete migration to v2
   kubectl scale deployment online-shop-v2 -n canary-ns --replicas=5
   kubectl scale deployment online-shop-v1 -n canary-ns --replicas=0
   ```

## Monitoring

Monitor your deployments during the canary process:

```bash
kubectl get pods -n canary-ns
kubectl get services -n canary-ns
```

## Cleanup

```bash
kubectl delete namespace canary-ns
```
