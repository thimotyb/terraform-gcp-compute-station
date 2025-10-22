#!/bin/bash
#######################################################
# Start Ubuntu Workstation VM
#######################################################

# Get directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source common configuration
source "${SCRIPT_DIR}/config.sh"

echo "Starting VM: ${INSTANCE_NAME} in zone ${GCP_ZONE}..."
gcloud compute instances start ${INSTANCE_NAME} \
  --zone=${GCP_ZONE} \
  --project=${GCP_PROJECT}
