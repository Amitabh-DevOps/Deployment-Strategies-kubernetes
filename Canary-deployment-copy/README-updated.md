# Canary Deployment in Kubernetes

This guide explains how to implement a canary deployment strategy using Kubernetes with a pod-based approach.

## What is Canary Deployment?

Canary deployment is a strategy where a new version of an application is gradually rolled out to a subset of users before making it available to everyone. This helps identify potential issues before they affect all users.

## Prerequisites

- Kubernetes cluster (Kind, Minikube, or any other)
- kubectl installed

## Pod-Based Canary Deployment Approach

This implementation uses a pod-based approach for canary deployment:
- Traffic distribution is controlled by the number of replicas
- A single service selects pods from both versions
- No complex ingress annotations required

## Setup Steps

### 1. Create the namespace

```bash
kubectl apply -f canary-namespace.yml
```

### 2. Deploy both versions with different replica counts

```bash
# Deploy v1 (stable version - without footer)
kubectl apply -f canary-v1-deployment.yaml  # 4 replicas (80% of traffic)

# Deploy v2 (canary version - with footer)
kubectl apply -f canary-v2-deployment.yaml  # 1 replica (20% of traffic)
```

### 3. Create the combined service that selects both versions

```bash
kubectl apply -f canary-combined-service.yaml
```

### 4. (Optional) Create the ingress for external access

```bash
kubectl apply -f ingress.yaml
```

## How it works

1. Both deployments use the same app label (`app: online-shop`) but different version labels
2. The service selects pods based only on the app label, not the version
3. Traffic is distributed proportionally to the number of pods for each version:
   - v1 (without footer): 4 pods = ~80% of traffic
   - v2 (with footer): 1 pod = ~20% of traffic

## Testing the Canary Deployment

### Option 1: Using port-forward to the service

```bash
kubectl port-forward -n canary-ns svc/online-shop-service 8080:80
```

Then access http://localhost:8080 multiple times. You should see:
- The v1 version (without footer) approximately 80% of the time
- The v2 version (with footer) approximately 20% of the time

### Option 2: Using ingress

If you've set up the ingress controller:

```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
```

Then access http://localhost:8080 multiple times.

### Option 3: Using curl in a loop

```bash
for i in {1..20}; do 
  echo -n "Request $i: "
  if curl -s http://localhost:8080 | grep -q "footer"; then 
    echo "Version 2 (with footer)"
  else 
    echo "Version 1 (without footer)"
  fi
  sleep 0.5
done
```

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
# Check pods
kubectl get pods -n canary-ns

# Check the distribution of pods
kubectl get pods -n canary-ns --show-labels

# Check the service
kubectl describe svc online-shop-service -n canary-ns
```

## Cleanup

```bash
kubectl delete namespace canary-ns
```

## Advantages of Pod-Based Canary Deployment

1. **Simplicity**: No complex annotations or configurations needed
2. **Reliability**: Works consistently across different Kubernetes environments
3. **Visibility**: Easy to understand and visualize the traffic distribution
4. **Compatibility**: Works with any application without special requirements
5. **No MIME type issues**: Avoids problems with static assets and content types

## Comparison with Ingress-Based Canary

| Feature | Pod-Based Canary | Ingress-Based Canary |
|---------|-----------------|---------------------|
| **Complexity** | Low | High |
| **Precision** | Based on pod count | Percentage-based |
| **Requirements** | Standard Kubernetes | Ingress controller with canary support |
| **Configuration** | Simple | Complex annotations |
| **Reliability** | High | Can have issues with static assets |
| **Resource Usage** | Efficient | Similar |
| **Header/Cookie Routing** | Not supported | Supported |
| **Implementation** | Single service, multiple deployments | Multiple services, ingress rules |
