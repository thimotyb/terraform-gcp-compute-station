#!/bin/bash
#######################################################
# Connect to Ubuntu Workstation via RDP using IAP
#######################################################

PROJECT="cegeka-gcp-awareness"
ZONE="europe-west1-c"
INSTANCE="ubuntu-workstation"
LOCAL_PORT="3389"

echo "========================================="
echo "Starting IAP Tunnel for RDP"
echo "========================================="
echo ""
echo "Creating IAP tunnel to ${INSTANCE}..."
echo "You can connect via Remote Desktop to: localhost:${LOCAL_PORT}"
echo ""
echo "Press Ctrl+C to close the tunnel when done"
echo ""
echo "========================================="

gcloud compute start-iap-tunnel ${INSTANCE} 3389 \
  --local-host-port=localhost:${LOCAL_PORT} \
  --zone=${ZONE} \
  --project=${PROJECT}