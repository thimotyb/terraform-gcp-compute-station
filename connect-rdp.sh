#!/bin/bash
#######################################################
# Connect to Ubuntu Workstation via RDP using IAP
#######################################################

# Get directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source common configuration
source "${SCRIPT_DIR}/config.sh"

LOCAL_PORT="3389"

echo "========================================="
echo "Starting IAP Tunnel for RDP"
echo "========================================="
echo ""
echo "Project:  ${GCP_PROJECT}"
echo "Zone:     ${GCP_ZONE}"
echo "Instance: ${INSTANCE_NAME}"
echo ""
echo "Creating IAP tunnel to ${INSTANCE_NAME}..."
echo "You can connect via Remote Desktop to: localhost:${LOCAL_PORT}"
echo ""
echo "Press Ctrl+C to close the tunnel when done"
echo ""
echo "========================================="

gcloud compute start-iap-tunnel ${INSTANCE_NAME} 3389 \
  --local-host-port=localhost:${LOCAL_PORT} \
  --zone=${GCP_ZONE} \
  --project=${GCP_PROJECT}