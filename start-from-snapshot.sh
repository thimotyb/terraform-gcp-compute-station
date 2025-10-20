#!/usr/bin/env bash
# Recreate the workstation VM from the most recent snapshot and restore the boot disk.
set -euo pipefail

INSTANCE="${INSTANCE_NAME:-ubuntu-workstation}"
ZONE="${GCP_ZONE:-europe-west1-c}"
PROJECT="${GCP_PROJECT:-}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-highmem-4}"
TAGS="${NETWORK_TAGS:-rdp-server,iap-ssh}"
NETWORK="${GCP_NETWORK:-default}"
DISK_TYPE="${DISK_TYPE:-pd-standard}"
DISK="${BOOT_DISK_NAME:-$INSTANCE}"
SNAPSHOT_FILTER="${SNAPSHOT_FILTER:-^${INSTANCE}-snapshot-}"
STARTUP_SCRIPT_PATH="${STARTUP_SCRIPT_PATH:-startup-script.sh}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-}"
SCOPES="${SCOPES:-https://www.googleapis.com/auth/cloud-platform}"

if [[ -z "${INSTANCE}" ]]; then
  echo "INSTANCE_NAME must not be empty" >&2
  exit 1
fi

PROJECT_FLAG=()
if [[ -n "${PROJECT}" ]]; then
  PROJECT_FLAG+=(--project "${PROJECT}")
fi

SNAPSHOT_NAME=$(gcloud compute snapshots list \
  --filter="name~'${SNAPSHOT_FILTER}'" \
  --sort-by=~creationTimestamp \
  --limit=1 \
  --format="value(name)" \
  "${PROJECT_FLAG[@]}")

if [[ -z "${SNAPSHOT_NAME}" ]]; then
  echo "No snapshot found matching filter ${SNAPSHOT_FILTER}" >&2
  exit 1
fi

# Ensure no instance with the same name exists
if gcloud compute instances describe "${INSTANCE}" --zone "${ZONE}" "${PROJECT_FLAG[@]}" >/dev/null 2>&1; then
  echo "Instance ${INSTANCE} already exists in ${ZONE}; delete it before running this script." >&2
  exit 1
fi

# Remove existing disk if present (stale resource)
if gcloud compute disks describe "${DISK}" --zone "${ZONE}" "${PROJECT_FLAG[@]}" >/dev/null 2>&1; then
  echo "Deleting stale disk ${DISK}..."
  gcloud compute disks delete "${DISK}" --zone "${ZONE}" "${PROJECT_FLAG[@]}" --quiet
fi

echo "Latest snapshot: ${SNAPSHOT_NAME}"

echo "Recreating boot disk ${DISK} from snapshot..."
gcloud compute disks create "${DISK}" \
  --source-snapshot "${SNAPSHOT_NAME}" \
  --type "${DISK_TYPE}" \
  --zone "${ZONE}" \
  "${PROJECT_FLAG[@]}"

INSTANCE_ARGS=(
  --zone "${ZONE}"
  --machine-type "${MACHINE_TYPE}"
  --network "${NETWORK}"
  --boot-disk-name "${DISK}"
  --boot-disk-auto-delete
)

if [[ -n "${TAGS}" ]]; then
  INSTANCE_ARGS+=(--tags "${TAGS}")
fi

if [[ -n "${SCOPES}" ]]; then
  INSTANCE_ARGS+=(--scopes "${SCOPES}")
fi

if [[ -n "${SERVICE_ACCOUNT}" ]]; then
  INSTANCE_ARGS+=(--service-account "${SERVICE_ACCOUNT}")
fi

if [[ -f "${STARTUP_SCRIPT_PATH}" ]]; then
  INSTANCE_ARGS+=(--metadata enable-oslogin=TRUE)
  INSTANCE_ARGS+=(--metadata-from-file startup-script="${STARTUP_SCRIPT_PATH}")
else
  echo "Warning: startup script ${STARTUP_SCRIPT_PATH} not found; continuing without it." >&2
  INSTANCE_ARGS+=(--metadata enable-oslogin=TRUE)
fi

echo "Creating instance ${INSTANCE}..."
gcloud compute instances create "${INSTANCE}" \
  "${INSTANCE_ARGS[@]}" \
  "${PROJECT_FLAG[@]}"

echo "Instance ${INSTANCE} recreated from snapshot ${SNAPSHOT_NAME}"
