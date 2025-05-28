#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Setting up Canary Deployment in Kind Cluster ===${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo -e "${RED}kind is not installed. Please install kind first.${NC}"
    exit 1
fi

# Check if kind cluster exists
if ! kind get clusters | grep -q "dep-strg"; then
    echo -e "${YELLOW}Creating Kind cluster...${NC}"
    cd ../
    kind create cluster --config kind-config.yml --name dep-strg
    cd Canary-deployment/
else
    echo -e "${GREEN}Kind cluster 'dep-strg' already exists.${NC}"
fi

# Apply namespace
echo -e "${YELLOW}Creating namespace...${NC}"
kubectl apply -f canary-namespace.yml

# Apply service
echo -e "${YELLOW}Creating service...${NC}"
kubectl apply -f canary-svc.yml

# Apply initial deployment (v1 - without footer)
echo -e "${YELLOW}Deploying v1 (without footer) with 4 replicas...${NC}"
kubectl apply -f onlineshop-without-footer-canary-deployment.yaml

# Wait for deployment to be ready
echo -e "${YELLOW}Waiting for v1 deployment to be ready...${NC}"
kubectl wait --for=condition=available --timeout=60s deployment/canary-online-shop-v1 -n canary-ns

# Show pods
echo -e "${GREEN}Current pods:${NC}"
kubectl get pods -n canary-ns

# Setup port forwarding
echo -e "${YELLOW}Setting up port forwarding...${NC}"
echo -e "${YELLOW}If port forwarding fails, run this command manually:${NC}"
echo -e "${GREEN}kubectl port-forward --address 0.0.0.0 svc/canary-deployment-service 3000:3000 -n canary-ns${NC}"

# Try to set up port forwarding in the background
kubectl port-forward --address 0.0.0.0 svc/canary-deployment-service 3000:3000 -n canary-ns &
PORT_FORWARD_PID=$!

echo -e "${GREEN}=== Initial setup complete ===${NC}"
echo -e "${YELLOW}Access the application at: http://localhost:3000${NC}"
echo -e "${YELLOW}Currently serving v1 (without footer) on all pods${NC}"
echo ""
echo -e "${GREEN}=== Canary Deployment Commands ===${NC}"
echo -e "${YELLOW}To deploy canary version (v2 with footer, 1 replica):${NC}"
echo -e "${GREEN}kubectl apply -f onlineshop-canary-deployment.yaml${NC}"
echo ""
echo -e "${YELLOW}To monitor pods during canary deployment:${NC}"
echo -e "${GREEN}watch kubectl get pods -n canary-ns${NC}"
echo ""
echo -e "${YELLOW}To scale up canary version (v2) to more replicas:${NC}"
echo -e "${GREEN}kubectl scale deployment canary-online-shop-v2 -n canary-ns --replicas=2${NC}"
echo ""
echo -e "${YELLOW}To scale down original version (v1):${NC}"
echo -e "${GREEN}kubectl scale deployment canary-online-shop-v1 -n canary-ns --replicas=3${NC}"
echo ""
echo -e "${YELLOW}To complete the canary rollout (fully migrate to v2):${NC}"
echo -e "${GREEN}kubectl scale deployment canary-online-shop-v2 -n canary-ns --replicas=5${NC}"
echo -e "${GREEN}kubectl scale deployment canary-online-shop-v1 -n canary-ns --replicas=0${NC}"

# Keep the script running to maintain port forwarding
echo -e "${YELLOW}Press Ctrl+C to stop port forwarding and exit${NC}"
wait $PORT_FORWARD_PID
