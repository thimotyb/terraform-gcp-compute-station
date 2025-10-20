# Snapshot-Based Shutdown Workflow

These helper scripts let you park the workstation VM without paying for the persistent boot disk. When you finish a session, snapshot the boot disk and delete the instance. When you need it again, recreate the disk from the newest snapshot and spin the VM back up.

## Prerequisites
- `gcloud` CLI installed and authenticated for the target project.
- APIs enabled: `compute.googleapis.com` (already required by Terraform).
- Terraform should not manage `google_compute_instance.ubuntu_workstation` while you use these scripts. Remove it from state with `terraform state rm google_compute_instance.ubuntu_workstation` or comment it out before your next `terraform apply`.

## Stop & Snapshot (`stop-with-snapshot.sh`)
1. Run `./stop-with-snapshot.sh` from the repo root.
2. The script will:
   - Stop the `ubuntu-workstation` VM in `europe-west1-c`.
   - Snapshot the boot disk with a timestamped name (`ubuntu-workstation-snapshot-YYYYMMDD-HHMMSSZ`).
   - Delete the instance so the boot disk no longer incurs charges.
3. Snapshots use regional storage; you now only pay the snapshot rate until you recreate the VM.

## Restart from Snapshot (`start-from-snapshot.sh`)
1. Run `./start-from-snapshot.sh` from the repo root.
2. The script finds the newest snapshot matching `ubuntu-workstation-snapshot-*`, recreates the boot disk, and provisions a VM with the same machine type, tags, metadata, and startup script.
3. After the VM boots, it behaves exactly as it did when you ran the stop script (minus any in-flight changes since the snapshot was captured).

## Customising Settings
Both scripts can be adjusted via environment variables without editing the files.

| Variable | Default | Purpose |
| --- | --- | --- |
| `GCP_PROJECT` | (active `gcloud` project) | Target project ID. |
| `GCP_ZONE` | `europe-west1-c` | Zone for the instance and disk. |
| `INSTANCE_NAME` | `ubuntu-workstation` | VM name (and default disk name). |
| `BOOT_DISK_NAME` | same as `INSTANCE_NAME` | Override disk name if customised. |
| `SNAPSHOT_PREFIX` | `<instance>-snapshot` | Prefix for created snapshots. |
| `MACHINE_TYPE` | `e2-highmem-4` | Machine type when recreating the VM. |
| `NETWORK_TAGS` | `rdp-server,iap-ssh` | Network tags to attach during start. |
| `GCP_NETWORK` | `default` | VPC network for the instance. |
| `DISK_TYPE` | `pd-standard` | Disk type when recreating from snapshot. |
| `STARTUP_SCRIPT_PATH` | `startup-script.sh` | File to attach as startup script on creation. |
| `SERVICE_ACCOUNT` | (default service account) | Service account email to attach. |
| `SCOPES` | `https://www.googleapis.com/auth/cloud-platform` | OAuth scopes for the instance. |

Example override:

```bash
GCP_PROJECT=my-project GCP_ZONE=europe-west1-b ./stop-with-snapshot.sh
```

## Clean-Up
Snapshots accumulate over time. Periodically prune older ones you no longer need:

```bash
gcloud compute snapshots list --filter="name~'ubuntu-workstation-snapshot-'"
gcloud compute snapshots delete ubuntu-workstation-snapshot-20240101-120000Z
```

Run a short validation cycle after adopting the workflow (stop → start → verify) to ensure everything comes back as expected.
