#!/bin/bash
#######################################################
# Upload and Run XRDP Fix Script on VM
#######################################################

# Get directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source common configuration
source "${SCRIPT_DIR}/config.sh"

echo "========================================="
echo "Uploading fix-xrdp-install.sh to VM..."
echo "========================================="
echo ""
echo "Project:  ${GCP_PROJECT}"
echo "Zone:     ${GCP_ZONE}"
echo "Instance: ${INSTANCE_NAME}"
echo ""

# Upload the fix script to the VM using IAP tunnel
gcloud compute scp "${SCRIPT_DIR}/fix-xrdp-install.sh" ${INSTANCE_NAME}:/tmp/ \
  --zone=${GCP_ZONE} \
  --project=${GCP_PROJECT} \
  --tunnel-through-iap

echo ""
echo "========================================="
echo "Running XRDP installation on VM..."
echo "========================================="
echo ""

# Run the fix script on the VM using IAP tunnel
gcloud compute ssh ${INSTANCE_NAME} \
  --zone=${GCP_ZONE} \
  --project=${GCP_PROJECT} \
  --tunnel-through-iap \
  --command="sudo bash /tmp/fix-xrdp-install.sh"

echo ""
echo "========================================="
echo "XRDP Fix Complete!"
echo "========================================="
echo ""
echo "You can now connect via RDP:"
echo "1. Run: ./connect-rdp.sh"
echo "2. Connect Remote Desktop to: localhost:3389"
echo "3. Username: ubuntu"
echo "4. Password: ChangeMe123!"
echo ""
