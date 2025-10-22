# Configuration Guide

## Single Source of Truth: terraform.tfvars

All configuration is now centralized in `terraform.tfvars`. Helper scripts automatically read values from this file.

### Key Configuration Variables

```hcl
# GCP Settings
gcp_project = "your-project-id"
gcp_region  = "europe-west1"
gcp_zone    = "europe-west1-c"

# Compute Instance
instance_name = "ubuntu-workstation"
machine_type  = "e2-highmem-4"
disk_size_gb  = 400
```

## Changing Zone or Region

To change the zone or region for your workstation:

### Step 1: Edit terraform.tfvars

```bash
# Edit the file
nano terraform.tfvars

# Or use sed to update values
sed -i 's/europe-west1-c/us-central1-a/' terraform.tfvars
sed -i 's/europe-west1/us-central1/' terraform.tfvars
```

**Important:** Ensure the zone matches the region:
- `europe-west1` region → `europe-west1-a`, `europe-west1-b`, `europe-west1-c`, etc.
- `us-central1` region → `us-central1-a`, `us-central1-b`, etc.

### Step 2: Apply Terraform Changes

```bash
terraform plan   # Review changes
terraform apply  # Apply changes
```

**⚠️ Warning:** Changing zones will destroy and recreate the VM! Create a snapshot first if you want to preserve data.

### Step 3: Use Helper Scripts

All helper scripts now automatically use the new zone:

```bash
./start.sh              # Uses zone from terraform.tfvars
./stop.sh               # Uses zone from terraform.tfvars
./connect-rdp.sh        # Uses zone from terraform.tfvars
```

## How It Works

### config.sh

The `config.sh` file:
1. Parses `terraform.tfvars`
2. Exports variables: `GCP_PROJECT`, `GCP_ZONE`, `GCP_REGION`, `INSTANCE_NAME`
3. Is automatically sourced by all helper scripts

### Scripts That Use config.sh

| Script | Purpose |
|--------|---------|
| `start.sh` | Start the VM |
| `stop.sh` | Stop the VM |
| `connect-rdp.sh` | Connect via RDP using IAP tunnel |
| `run-fix-xrdp.sh` | Install XRDP on existing VM |
| `start-from-snapshot.sh` | Recreate VM from snapshot |
| `stop-with-snapshot.sh` | Snapshot and delete VM |

## Environment Variable Overrides

You can still override values using environment variables:

```bash
# Override for a single command
GCP_ZONE=us-central1-a ./start.sh

# Export for the session
export GCP_ZONE=us-central1-a
./start.sh
./connect-rdp.sh
```

## Snapshot Scripts

The snapshot scripts (`start-from-snapshot.sh` and `stop-with-snapshot.sh`) use `config.sh` but fall back to default values if variables aren't set:

```bash
# Uses terraform.tfvars if available
./stop-with-snapshot.sh

# Or use environment variables
INSTANCE_NAME=my-vm GCP_ZONE=us-central1-a ./stop-with-snapshot.sh
```

## Troubleshooting

### "ERROR: terraform.tfvars not found"

Make sure you're running scripts from the project root directory where `terraform.tfvars` is located.

### "ERROR: Failed to read required variables"

Check that your `terraform.tfvars` contains:
- `gcp_project`
- `gcp_zone`
- `instance_name`

### Variables are empty

Ensure values in `terraform.tfvars` are properly quoted:

```hcl
# Correct
gcp_zone = "europe-west1-c"

# Incorrect
gcp_zone = europe-west1-c
```

## Benefits of This Approach

✅ **Single source of truth** - Update zone in one place
✅ **No hardcoded values** - Scripts adapt to your configuration
✅ **Consistency** - Terraform and scripts always in sync
✅ **Flexibility** - Environment variables still work for overrides
✅ **Easy migration** - Change regions without updating multiple files

## Migration Guide

If you have old scripts with hardcoded values:

### Before (Hardcoded)
```bash
ZONE="europe-west1-c"
PROJECT="my-project"
```

### After (Dynamic)
```bash
source "${SCRIPT_DIR}/config.sh"
# Variables now available:
# - $GCP_ZONE
# - $GCP_PROJECT
# - $INSTANCE_NAME
```

All official scripts in this repository have been updated to use the new configuration system.
