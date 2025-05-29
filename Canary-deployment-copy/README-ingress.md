# Canary Deployment with Ingress in Kubernetes

This guide explains how to implement a canary deployment strategy using Kubernetes Ingress in a Kind cluster.

## What is Canary Deployment?

Canary deployment is a strategy where a new version of an application is gradually rolled out to a subset of users before making it available to everyone. This helps identify potential issues before they affect all users.

## Prerequisites

- Kind cluster running
- kubectl installed

## Setup Steps

### 1. Install the Ingress Controller for Kind

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

### 2. Create the namespace

```bash
kubectl apply -f canary-namespace.yml
```

### 3. Deploy both versions

```bash
# Deploy v1 (stable version - without footer)
kubectl apply -f canary-v1-deployment.yaml

# Deploy v2 (canary version - with footer)
kubectl apply -f canary-v2-deployment.yaml
```

### 4. Create the services for each version

```bash
# Create service for v1
kubectl apply -f service-v1.yaml

# Create service for v2
kubectl apply -f service-v2.yaml
```

### 5. Apply the main ingress

```bash
kubectl apply -f main-ingress.yaml
```

### 6. Apply the canary ingress

```bash
kubectl apply -f canary-ingress.yaml
```

## How it works

1. The main ingress routes all traffic to the v1 service by default
2. The canary ingress has annotations that tell the ingress controller to route a percentage of traffic to v2:
   - `nginx.ingress.kubernetes.io/canary: "true"` - Marks this ingress as a canary
   - `nginx.ingress.kubernetes.io/canary-weight: "20"` - Routes 20% of traffic to v2
   - `nginx.ingress.kubernetes.io/canary-by-header: "X-Canary"` - Routes traffic with header "X-Canary: always" to v2
3. Both ingress resources use `ingressClassName: nginx` to specify which controller should handle them
4. The configuration-snippet annotation ensures proper MIME types for JavaScript, CSS, and other static files

## Testing the Canary Deployment

### 1. Port-forward the ingress controller service

```bash
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 --address 0.0.0.0
```

### 2. Access the application

Open your browser or use curl to access:
```
http://YOUR_EC2_IP:8080
```

Refresh multiple times - you should see:
- The v1 version (without footer) approximately 80% of the time
- The v2 version (with footer) approximately 20% of the time

### 3. Test with curl in a loop

To verify the traffic distribution:

```bash
for i in {1..20}; do 
  echo -n "Request $i: "
  if curl -s http://YOUR_EC2_IP:8080 | grep -q "footer"; then 
    echo "Version 2 (with footer)"
  else 
    echo "Version 1 (without footer)"
  fi
  sleep 0.5
done
```

### 4. Force traffic to the canary version

You can force traffic to the canary version using the X-Canary header:

```bash
curl -H "X-Canary: always" http://YOUR_EC2_IP:8080
```

This should always show the version with footer.

## Adjusting the Canary Weight

To change the percentage of traffic going to the canary version:

1. Edit the canary-ingress.yaml file and change the canary-weight annotation
2. Apply the updated ingress:
   ```bash
   kubectl apply -f canary-ingress.yaml
   ```

Or use kubectl patch:
   ```bash
   kubectl patch ingress canary-ingress -n canary-ns --type=json \
     -p='[{"op": "replace", "path": "/metadata/annotations/nginx.ingress.kubernetes.io~1canary-weight", "value": "50"}]'
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

3. Increase to 80% traffic to v2:
   ```
   nginx.ingress.kubernetes.io/canary-weight: "80"
   ```

4. Complete the rollout (migrate all traffic to v2):
   - Option 1: Update the main ingress to point to v2:
     ```yaml
     backend:
       service:
         name: online-shop-v2
         port:
           number: 80
     ```
   - Option 2: Delete the canary ingress and create a new main ingress pointing to v2

## Monitoring

Monitor your deployments during the canary process:

```bash
# Check pods
kubectl get pods -n canary-ns

# Check services
kubectl get services -n canary-ns

# Check ingress resources
kubectl get ingress -n canary-ns

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

## Troubleshooting

### Ingress controller pod stuck in Pending state

If the ingress controller pod is stuck in Pending state with a node selector error:

```bash
kubectl patch deployment ingress-nginx-controller -n ingress-nginx --type=json \
  -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector"}]'
```

### Cannot access the application

If you cannot access the application after setting up everything:

1. Check if the ingress controller is running:
   ```bash
   kubectl get pods -n ingress-nginx
   ```

2. Check the ingress resources:
   ```bash
   kubectl describe ingress -n canary-ns
   ```

3. Check the ingress controller logs:
   ```bash
   kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
   ```

4. Try port-forwarding directly to one of the services to verify they're working:
   ```bash
   kubectl port-forward -n canary-ns service/online-shop-v1 8081:80 --address 0.0.0.0
   kubectl port-forward -n canary-ns service/online-shop-v2 8082:80 --address 0.0.0.0
   ```

### MIME type errors in browser console

If you see errors related to MIME types in the browser console, make sure the configuration-snippet annotation is correctly applied to both ingress resources.

### Testing with curl and headers

To test the header-based canary routing:

```bash
# Force traffic to canary version
curl -H "X-Canary: always" http://YOUR_EC2_IP:8080

# Force traffic to stable version
curl -H "X-Canary: never" http://YOUR_EC2_IP:8080
```

## Cleanup

```bash
# Delete the canary namespace (removes all resources in it)
kubectl delete namespace canary-ns

# Delete the ingress-nginx namespace
kubectl delete namespace ingress-nginx
```
