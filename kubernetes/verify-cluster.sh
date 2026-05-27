#!/usr/bin/env bash
# Orbit-Cloud cluster health validation script
set -euo pipefail

echo "=========================================================="
echo "    Orbit-Cloud: Cluster Health Verification Report"
echo "=========================================================="
FAILED=0

# Helper function for checking binary status
check_status() {
    local component="$1"
    local status="$2"
    local details="$3"
    
    if [ "$status" = "OK" ]; then
        echo -e "[\e[32mOK\e[0m] $component: $details"
    else
        echo -e "[\e[31mFAIL\e[0m] $component: $details"
        FAILED=$((FAILED + 1))
    fi
}

# 1. Verify all 3 nodes are Ready
echo "[*] Checking cluster node states..."
nodes_total=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo 0)
nodes_ready=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "Ready" || echo 0)

if [ "$nodes_ready" -eq 3 ]; then
    check_status "Nodes" "OK" "3/3 nodes are in the Ready state."
else
    check_status "Nodes" "FAIL" "Only $nodes_ready of $nodes_total nodes are Ready."
    kubectl get nodes || true
fi

# 2. Verify Cilium is active
echo "[*] Checking Cilium agent health..."
cilium_pods=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=cilium-agent --no-headers 2>/dev/null | wc -l || echo 0)
cilium_running=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=cilium-agent --no-headers 2>/dev/null | grep -c "Running" || echo 0)

if [ "$cilium_running" -eq 3 ]; then
    check_status "Cilium CNI" "OK" "3/3 agent pods are running on host interfaces."
else
    check_status "Cilium CNI" "FAIL" "Only $cilium_running of $cilium_pods agents are Running."
fi

# 3. Verify MetalLB operator
echo "[*] Checking MetalLB daemon states..."
metallb_pods=$(kubectl get pods -n kube-system -l app=metallb --no-headers 2>/dev/null | wc -l || echo 0)
metallb_running=$(kubectl get pods -n kube-system -l app=metallb --no-headers 2>/dev/null | grep -c "Running" || echo 0)

if [ "$metallb_running" -gt 0 ]; then
    check_status "MetalLB" "OK" "MetalLB controller and speaker pods are Running."
else
    check_status "MetalLB" "FAIL" "MetalLB speaker/controllers are not running."
fi

# 4. Verify NGINX Ingress External IP
echo "[*] Checking NGINX Ingress LoadBalancer status..."
ingress_ip=$(kubectl get svc -n kube-system ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -n "$ingress_ip" ]; then
    check_status "NGINX Ingress" "OK" "External IP assigned: $ingress_ip"
else
    check_status "NGINX Ingress" "FAIL" "No external IP allocated by MetalLB yet."
    kubectl get svc -n kube-system ingress-nginx-controller || true
fi

# 5. Verify MinIO cluster health
echo "[*] Checking MinIO storage replicas..."
minio_ready=$(kubectl get statefulset -n minio minio -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)

if [ "$minio_ready" -eq 3 ]; then
    check_status "MinIO Storage" "OK" "3/3 storage replicas are online and healthy."
else
    check_status "MinIO Storage" "FAIL" "Only $minio_ready of 3 replicas are online."
    kubectl get pods -n minio || true
fi

# 6. Verify MinIO external S3 IP allocation
echo "[*] Checking MinIO external IP allocation..."
minio_ip=$(kubectl get svc -n minio minio-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -n "$minio_ip" ]; then
    check_status "MinIO Service" "OK" "External S3 API endpoints assigned on IP: $minio_ip"
else
    check_status "MinIO Service" "FAIL" "No external IP allocated for MinIO S3 API yet."
    kubectl get svc -n minio minio-lb || true
fi

echo "=========================================================="
if [ "$FAILED" -eq 0 ]; then
    echo -e "\e[32m[STATUS: PASS] Orbit-Cloud is healthy and fully operational!\e[0m"
else
    echo -e "\e[31m[STATUS: FAIL] $FAILED health checks failed. Check logs above.\e[0m"
fi
echo "=========================================================="
