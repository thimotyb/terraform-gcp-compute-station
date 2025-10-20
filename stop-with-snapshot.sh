#!/usr/bin/env bash
# Stop the workstation VM, snapshot its boot disk, and delete the instance to avoid disk charges.
set -euo pipefail

INSTANCE="${INSTANCE_NAME:-ubuntu-workstation}"
ZONE="${GCP_ZONE:-europe-west1-c}"
PROJECT="${GCP_PROJECT:-}"
DISK="${BOOT_DISK_NAME:-$INSTANCE}"
STAMP="$(date -u +'%Y%m%d-%H%M%SZ')"
SNAPSHOT_PREFIX="${SNAPSHOT_PREFIX:-${INSTANCE}-snapshot}"
SNAPSHOT_NAME="${SNAPSHOT_PREFIX}-${STAMP}"

if [[ -z "${INSTANCE}" ]]; then
  echo "INSTANCE_NAME must not be empty" >&2
  exit 1
fi

PROJECT_FLAG=()
if [[ -n "${PROJECT}" ]]; then
  PROJECT_FLAG+=(--project "${PROJECT}")
fi

echo "Stopping instance ${INSTANCE} in ${ZONE}..."
gcloud compute instances stop "${INSTANCE}" --zone "${ZONE}" "${PROJECT_FLAG[@]}"

echo "Creating snapshot ${SNAPSHOT_NAME} from disk ${DISK}..."
gcloud compute disks snapshot "${DISK}" \
  --snapshot-names "${SNAPSHOT_NAME}" \
  --zone "${ZONE}" \
  "${PROJECT_FLAG[@]}"

echo "Deleting instance ${INSTANCE} to release the boot disk..."
gcloud compute instances delete "${INSTANCE}" --zone "${ZONE}" "${PROJECT_FLAG[@]}" --quiet

echo "Snapshot complete: ${SNAPSHOT_NAME}"
