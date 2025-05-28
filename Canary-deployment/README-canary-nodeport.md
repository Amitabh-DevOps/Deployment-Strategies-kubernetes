# Canary Deployment with NodePort in Kubernetes

This guide explains how to implement a canary deployment strategy using a single NodePort service in Kubernetes.

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

### 2. Deploy both versions with different replica counts

```bash
kubectl apply -f canary-v1-deployment.yaml  # 4 replicas (80% of traffic)
kubectl apply -f canary-v2-deployment.yaml  # 1 replica (20% of traffic)
```

### 3. Deploy the combined service that selects both versions

```bash
kubectl apply -f canary-combined-service.yaml
```

## How it works

1. Both deployments use the same app label (`app: online-shop`) but different version labels
2. The service selects pods based only on the app label, not the version
3. Traffic is distributed proportionally to the number of pods for each version:
   - v1 (without footer): 4 pods = ~80% of traffic
   - v2 (with footer): 1 pod = ~20% of traffic
4. All traffic goes through a single NodePort (30080)

## Testing the Canary Deployment

Access the application at:
```
http://54.237.87.116:30080
```

Refresh multiple times - you should see:
- The v1 version (without footer) approximately 80% of the time
- The v2 version (with footer) approximately 20% of the time

## Adjusting the Traffic Split

To change the percentage of traffic going to each version, adjust the number of replicas:

```bash
# Increase canary traffic to ~40% (3:2 ratio)
kubectl scale deployment online-shop-v1 -n canary-ns --replicas=3
kubectl scale deployment online-shop-v2 -n canary-ns --replicas=2

# Increase canary traffic to ~60% (2:3 ratio)
kubectl scale deployment online-shop-v1 -n canary-ns --replicas=2
kubectl scale deployment online-shop-v2 -n canary-ns --replicas=3

# Complete migration to v2 (0:5 ratio)
kubectl scale deployment online-shop-v1 -n canary-ns --replicas=0
kubectl scale deployment online-shop-v2 -n canary-ns --replicas=5
```

## Monitoring

Monitor your deployments during the canary process:

```bash
kubectl get pods -n canary-ns
```

## Cleanup

```bash
kubectl delete namespace canary-ns
```
