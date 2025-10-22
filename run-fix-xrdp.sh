#!/bin/bash
#######################################################
# Upload and Run XRDP Fix Script on VM
#######################################################

PROJECT="cegeka-gcp-awareness"
ZONE="europe-west1-c"
INSTANCE="ubuntu-workstation"

echo "========================================="
echo "Uploading fix-xrdp-install.sh to VM..."
echo "========================================="

# Upload the fix script to the VM
gcloud compute scp fix-xrdp-install.sh ${INSTANCE}:/tmp/ \
  --zone=${ZONE} \
  --project=${PROJECT}

echo ""
echo "========================================="
echo "Running XRDP installation on VM..."
echo "========================================="
echo ""

# Run the fix script on the VM
gcloud compute ssh ${INSTANCE} \
  --zone=${ZONE} \
  --project=${PROJECT} \
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
