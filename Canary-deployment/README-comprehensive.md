# Canary Deployment in Kubernetes

This guide explains how to implement a canary deployment strategy in Kubernetes using two different approaches:
1. Using NGINX Ingress Controller with canary annotations
2. Using a single NodePort service with label selection

Both approaches achieve the same goal: gradually rolling out a new version of your application to a subset of users before making it available to everyone.

## Prerequisites

- Kind cluster running
- kubectl installed

## Approach 1: Canary Deployment with NGINX Ingress Controller

This approach uses the NGINX Ingress Controller's canary annotations to split traffic between versions.

### Setup Steps

#### 1. Install the Ingress Controller

For Kind clusters:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml
```

For other Kubernetes clusters:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

Wait for the ingress controller to be ready:
```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

#### 2. Create the namespace

```bash
kubectl apply -f canary-namespace.yml
```

#### 3. Deploy both versions

```bash
kubectl apply -f canary-v1-deployment.yaml  # 4 replicas (stable version)
kubectl apply -f canary-v2-deployment.yaml  # 1 replica (canary version)
```

### 3. Deploy the combined service that selects both versions

```bash
kubectl apply -f canary-combined-service.yaml
```

#### 5. Apply the main ingress

```bash
kubectl apply -f main-ingress.yaml
```

#### 6. Apply the canary ingress

```bash
kubectl apply -f canary-ingress.yaml
```

### How it works

1. The main ingress routes all traffic to the v1 service by default
2. The canary ingress has annotations that tell the ingress controller to route a percentage of traffic to v2:
   - `nginx.ingress.kubernetes.io/canary: "true"` - Marks this ingress as a canary
   - `nginx.ingress.kubernetes.io/canary-weight: "20"` - Routes 20% of traffic to v2

### Testing the Canary Deployment

For Kind clusters, you can access the application at:
```
http://localhost:80
```

For EC2 or other cloud environments, use your instance's public IP:
```
http://54.237.87.116:80
```

Refresh multiple times - you should see the v1 version (without footer) approximately 80% of the time and the v2 version (with footer) approximately 20% of the time.

### Adjusting the Canary Weight

To change the percentage of traffic going to the canary version:

1. Edit the canary-ingress.yaml file and change the canary-weight annotation
2. Apply the updated ingress:
   ```bash
   kubectl apply -f canary-ingress.yaml
   ```

### Gradual Rollout Example

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

## Approach 2: Canary Deployment with NodePort Service

This approach uses a single NodePort service that selects pods from both versions, with traffic distribution based on the number of replicas.

### Setup Steps

#### 1. Create the namespace

```bash
kubectl apply -f canary-namespace.yml
```

#### 2. Deploy both versions with different replica counts

```bash
kubectl apply -f canary-v1-deployment.yaml  # 4 replicas (80% of traffic)
kubectl apply -f canary-v2-deployment.yaml  # 1 replica (20% of traffic)
```

#### 3. Deploy the combined service that selects both versions

```bash
kubectl apply -f canary-combined-service.yaml
```

### How it works

1. Both deployments use the same app label (`app: online-shop`) but different version labels
2. The combined service selects pods based only on the app label, not the version
3. Traffic is distributed proportionally to the number of pods for each version:
   - v1 (without footer): 4 pods = ~80% of traffic
   - v2 (with footer): 1 pod = ~20% of traffic
4. All traffic goes through a single NodePort

### Testing the Canary Deployment

Access the application using the NodePort specified in your canary-combined-service.yaml:
```
http://54.237.87.116:30080
```

If port 30080 is already in use, you may need to modify the NodePort in the canary-combined-service.yaml file.

Refresh multiple times - you should see the v1 version (without footer) approximately 80% of the time and the v2 version (with footer) approximately 20% of the time.

### Adjusting the Traffic Split

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
kubectl get services -n canary-ns
kubectl get ingress -n canary-ns  # For Approach 1
```

## Cleanup

```bash
kubectl delete namespace canary-ns
kubectl delete namespace ingress-nginx  # For Approach 1
```

## Comparing the Approaches

### Approach 1: NGINX Ingress Controller
- Pros:
  - More precise control over traffic percentages
  - Can be adjusted without changing pod counts
  - Works well with external load balancers
- Cons:
  - Requires an Ingress Controller
  - More complex setup

### Approach 2: NodePort Service with Label Selection
- Pros:
  - Simpler setup
  - No additional controllers required
  - Works in any Kubernetes environment
- Cons:
  - Traffic split is based on pod counts, which may be less precise
  - Requires scaling deployments to adjust traffic percentages

Choose the approach that best fits your environment and requirements.
