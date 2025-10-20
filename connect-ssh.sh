#!/usr/bin/env bash
# Connect to a Compute Engine VM via SSH using its external IP.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <public-ip>" >&2
  exit 1
fi

IP="$1"
PROJECT="${GCP_PROJECT:-cegeka-gcp-awareness}"
USER="${SSH_USER:-ubuntu}"

INSTANCE_INFO=$(gcloud compute instances list \
  --project "${PROJECT}" \
  --filter="EXTERNAL_IP=${IP}" \
  --format="value(name,zone)")

if [[ -z "${INSTANCE_INFO}" ]]; then
  echo "No instance found in project ${PROJECT} with external IP ${IP}" >&2
  exit 2
fi

INSTANCE_NAME=$(awk '{print $1}' <<<"${INSTANCE_INFO}")
INSTANCE_ZONE=$(awk '{print $2}' <<<"${INSTANCE_INFO}" | sed 's#.*/##')

if [[ -z "${INSTANCE_NAME}" || -z "${INSTANCE_ZONE}" ]]; then
  echo "Failed to resolve instance information for ${IP}" >&2
  exit 3
fi

exec gcloud compute ssh "${USER}@${INSTANCE_NAME}" \
  --project "${PROJECT}" \
  --zone "${INSTANCE_ZONE}" \
  --ssh-flag="-o" --ssh-flag="StrictHostKeyChecking=no" \
  --ssh-flag="-o" --ssh-flag="UserKnownHostsFile=/dev/null"
