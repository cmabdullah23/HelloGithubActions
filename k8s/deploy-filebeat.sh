#!/bin/bash

# Deploy Filebeat for HelloGithubActions log collection
# This script deploys Filebeat as a DaemonSet with proper RBAC and configuration

set -e

echo "Deploying Filebeat for HelloGithubActions..."

# Apply RBAC configuration
echo "Creating ServiceAccount and RBAC..."
kubectl apply -f filebeat-rbac.yaml

# Apply ConfigMap
echo "Creating Filebeat ConfigMap..."
kubectl apply -f filebeat-configmap.yaml

# Apply DaemonSet
echo "Deploying Filebeat DaemonSet..."
kubectl apply -f filebeat-daemonset.yaml

# Wait for deployment
echo "Waiting for Filebeat pods to be ready..."
kubectl rollout status daemonset/filebeat --timeout=300s

# Check status
echo "Filebeat deployment status:"
kubectl get pods -l app=filebeat

echo "Filebeat deployed successfully!"
echo "To check logs: kubectl logs -l app=filebeat -f"
echo "To delete: kubectl delete -f ."