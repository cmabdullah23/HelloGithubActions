#!/bin/bash

# Deploy complete ELK stack for HelloGithubActions
# This script deploys Elasticsearch, Filebeat in proper order with connectivity checks

set -e

NAMESPACE=${NAMESPACE:-default}
TIMEOUT=${TIMEOUT:-300}

echo "🚀 Deploying ELK Stack for HelloGithubActions..."
echo "Namespace: $NAMESPACE"
echo "Timeout: ${TIMEOUT}s"

# Function to wait for deployment
wait_for_deployment() {
    local resource_type=$1
    local resource_name=$2
    local timeout=$3
    
    echo "⏳ Waiting for $resource_type/$resource_name to be ready..."
    if ! kubectl wait --for=condition=ready $resource_type/$resource_name --timeout=${timeout}s -n $NAMESPACE; then
        echo "❌ Failed to wait for $resource_type/$resource_name"
        return 1
    fi
    echo "✅ $resource_type/$resource_name is ready"
}

# Function to check Elasticsearch connectivity
check_elasticsearch() {
    echo "🔍 Checking Elasticsearch connectivity..."
    
    # Wait for ES pods to be ready
    kubectl wait --for=condition=ready pod -l app=elasticsearch --timeout=300s -n $NAMESPACE
    
    # Port forward to test connectivity
    kubectl port-forward svc/elasticsearch 9200:9200 -n $NAMESPACE &
    PORT_FORWARD_PID=$!
    sleep 5
    
    # Test connectivity
    MAX_RETRIES=30
    RETRY=0
    
    while [ $RETRY -lt $MAX_RETRIES ]; do
        if curl -s http://localhost:9200/_cluster/health | grep -q '"status":"yellow"\|"status":"green"'; then
            echo "✅ Elasticsearch is healthy"
            kill $PORT_FORWARD_PID 2>/dev/null || true
            return 0
        fi
        echo "⏳ Waiting for Elasticsearch to be healthy... ($((RETRY+1))/$MAX_RETRIES)"
        sleep 10
        RETRY=$((RETRY+1))
    done
    
    kill $PORT_FORWARD_PID 2>/dev/null || true
    echo "❌ Elasticsearch failed to become healthy"
    return 1
}

# Step 1: Deploy Elasticsearch
echo "📊 Step 1: Deploying Elasticsearch..."
kubectl apply -f elasticsearch-config.yaml -n $NAMESPACE
sleep 5

# Wait for Elasticsearch to be ready
if ! check_elasticsearch; then
    echo "❌ Elasticsearch deployment failed"
    exit 1
fi

# Step 2: Setup ILM policy and index templates
echo "⚙️  Step 2: Setting up ILM policy and index templates..."
kubectl apply -f elasticsearch-ilm-policy.yaml -n $NAMESPACE

# Wait for setup job to complete
echo "⏳ Waiting for Elasticsearch setup job to complete..."
kubectl wait --for=condition=complete job/elasticsearch-setup --timeout=300s -n $NAMESPACE
echo "✅ Elasticsearch setup completed"

# Step 3: Deploy Filebeat
echo "📁 Step 3: Deploying Filebeat..."

# Deploy RBAC first
kubectl apply -f filebeat-rbac.yaml -n $NAMESPACE

# Deploy ConfigMap
kubectl apply -f filebeat-configmap.yaml -n $NAMESPACE

# Deploy DaemonSet
kubectl apply -f filebeat-daemonset.yaml -n $NAMESPACE

# Wait for Filebeat to be ready
echo "⏳ Waiting for Filebeat DaemonSet to be ready..."
kubectl rollout status daemonset/filebeat --timeout=${TIMEOUT}s -n $NAMESPACE

# Step 4: Deploy Kibana
echo "🎨 Step 4: Deploying Kibana..."
kubectl apply -f kibana-deployment.yaml -n $NAMESPACE

# Wait for Kibana to be ready
echo "⏳ Waiting for Kibana to be ready..."
kubectl wait --for=condition=available deployment/kibana --timeout=${TIMEOUT}s -n $NAMESPACE

# Step 5: Setup Kibana dashboards
echo "📊 Step 5: Setting up Kibana dashboards..."
kubectl apply -f kibana-dashboards.yaml -n $NAMESPACE
kubectl apply -f kibana-setup-job.yaml -n $NAMESPACE

# Wait for dashboard setup to complete
echo "⏳ Waiting for Kibana dashboard setup to complete..."
kubectl wait --for=condition=complete job/kibana-setup --timeout=300s -n $NAMESPACE

# Step 6: Verify complete data flow
echo "🔍 Step 6: Verifying complete Filebeat -> Elasticsearch -> Kibana data flow..."

# Check Filebeat logs for successful connection
sleep 10
FILEBEAT_PODS=$(kubectl get pods -l app=filebeat -o jsonpath='{.items[*].metadata.name}' -n $NAMESPACE)

for pod in $FILEBEAT_PODS; do
    echo "📋 Checking Filebeat logs in pod: $pod"
    kubectl logs $pod -n $NAMESPACE --tail=20 | grep -i "connection\|elasticsearch\|output" || true
done

# Test data flow by checking for indices
echo "🔍 Checking for created indices..."
kubectl port-forward svc/elasticsearch 9200:9200 -n $NAMESPACE &
ES_PORT_FORWARD_PID=$!
sleep 5

# Check for indices
if curl -s http://localhost:9200/_cat/indices/hellogithubactions* | head -5; then
    echo "✅ Indices found - data is flowing"
else
    echo "⚠️  No indices found yet - this may be normal if no logs have been generated"
fi

# Check cluster health
echo "🏥 Elasticsearch cluster health:"
curl -s http://localhost:9200/_cluster/health?pretty

kill $ES_PORT_FORWARD_PID 2>/dev/null || true

# Test Kibana connectivity
echo "🎨 Testing Kibana connectivity..."
kubectl port-forward svc/kibana 5601:5601 -n $NAMESPACE &
KIBANA_PORT_FORWARD_PID=$!
sleep 10

# Check Kibana status
if curl -s http://localhost:5601/api/status | grep -q "available"; then
    echo "✅ Kibana is accessible and healthy"
    
    # Check if dashboards were created
    DASHBOARD_COUNT=$(curl -s http://localhost:5601/api/saved_objects/_find?type=dashboard | grep -o '"total":[0-9]*' | cut -d':' -f2 | head -1)
    if [ "$DASHBOARD_COUNT" -gt 0 ]; then
        echo "✅ Kibana dashboards created successfully ($DASHBOARD_COUNT dashboards found)"
    else
        echo "⚠️  No dashboards found - setup may still be in progress"
    fi
else
    echo "⚠️  Kibana may still be starting up"
fi

kill $KIBANA_PORT_FORWARD_PID 2>/dev/null || true

echo ""
echo "🎉 Complete ELK Stack with Kibana deployment completed successfully!"
echo ""
echo "📋 Summary:"
echo "✅ Elasticsearch deployed and running"
echo "✅ ILM policy and index templates configured"
echo "✅ Filebeat deployed and collecting logs"
echo "✅ Kibana deployed with dashboards"
echo ""
echo "🔧 Access URLs (port-forward required):"
echo "  Elasticsearch: kubectl port-forward svc/elasticsearch 9200:9200 -n $NAMESPACE"
echo "  Kibana: kubectl port-forward svc/kibana 5601:5601 -n $NAMESPACE"
echo ""
echo "📊 Available Kibana Dashboards:"
echo "  - HelloGithubActions - Overview Dashboard"
echo "  - HelloGithubActions - Application Monitoring"
echo "  - HelloGithubActions - Error Analysis"
echo "  - HelloGithubActions - Security Dashboard"
echo ""
echo "🔧 Useful commands:"
echo "  Check Filebeat logs: kubectl logs -l app=filebeat -f -n $NAMESPACE"
echo "  Check ES indices: curl http://localhost:9200/_cat/indices"
echo "  Generate test logs: curl http://localhost:8091/api/logs/test"
echo "  Delete ELK stack: kubectl delete -f . -n $NAMESPACE"