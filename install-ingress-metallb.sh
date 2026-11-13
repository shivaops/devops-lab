#!/bin/bash

# author  : Shiva Naik
# email   : shivanaik.it@gmail.com
# Mobile  : +973-38053730 Bahrain / +91-9820234089 India
# GitHub: 	 https://github.com/ShivaOps
# LinkedIn:  https://www.linkedin.com/in/shivaops/
# Portfolio: https://shivaops.github.io/
# YouTube:   https://www.youtube.com/@ShivaOps-AI

#set -ex

MAX_RETRIES=800  # Retry for up to 200*60 mins so that worker node will ready by that time
RETRY_COUNT=0
until [ "$(kubectl get nodes --no-headers | grep -c ' Ready ')" -eq 3 ]; do
  echo "⏳ Waiting for all 3 nodes to be Ready..."
  sleep 10
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
    echo "❌ Timeout: Nodes didn't become Ready in time."
    exit 1
  fi
done

echo "🛠️  Step 1: Installing Ingress-Nginx Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/baremetal/deploy.yaml

echo "⏳ Waiting for Ingress Controller Pod to be ready..."
sleep 20
kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo "✅ Ingress Controller installed and ready."

# -----------------------------------------------------------------

echo "🛠️  Step 2: Installing MetalLB components..."

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

echo "⏳ Waiting for MetalLB Pods to be ready..."
sleep 20
kubectl wait --namespace metallb-system \
  --for=condition=Ready pod \
  --selector=component=controller \
  --timeout=180s

kubectl wait --namespace metallb-system \
  --for=condition=Ready pod \
  --selector=component=speaker \
  --timeout=300s

echo "✅ MetalLB installed and ready."

# -----------------------------------------------------------------

echo "🛠️  Step 3: Configuring MetalLB IP Address Pool (172.16.0.100-172.16.0.110)..."

kubectl delete ValidatingWebhookConfiguration metallb-webhook-configuration

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  namespace: metallb-system
  name: my-ip-pool
spec:
  addresses:
  - 172.16.0.100-172.16.0.110
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  namespace: metallb-system
  name: my-l2-adv
spec: {}
EOF

echo "✅ MetalLB Address Pool and Advertisement configured."
kubectl get ipaddresspool -A
kubectl get l2advertisement -A

# -----------------------------------------------------------------

echo "🛠️  Step 4: Patching Ingress Controller service to be of type LoadBalancer..."

kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec": {"type": "LoadBalancer", "externalTrafficPolicy": "Local"}}'

echo "⏳ Waiting 10 seconds for Service update..."
sleep 10

echo "✅ Ingress Controller Service changed to LoadBalancer."

# -----------------------------------------------------------------

echo "✅✅✅ All Setup Completed Successfully!"
echo "Now create your Ingress resource and access via the assigned MetalLB IP (example: http://smarttrip.shivaops.com)"
