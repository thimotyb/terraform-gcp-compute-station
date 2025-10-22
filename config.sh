#!/bin/bash
#######################################################
# Common Configuration for All Helper Scripts
# Reads values from terraform.tfvars
#######################################################

# Get directory where config.sh is located
CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to extract value from terraform.tfvars
get_tfvar() {
    local key=$1
    local tfvars_file="${CONFIG_DIR}/terraform.tfvars"

    if [ ! -f "$tfvars_file" ]; then
        echo "ERROR: terraform.tfvars not found at $tfvars_file" >&2
        return 1
    fi

    # Extract value, handling quotes and comments
    grep "^[[:space:]]*${key}[[:space:]]*=" "$tfvars_file" | \
        head -n1 | \
        sed 's/^[^=]*=[[:space:]]*//' | \
        sed 's/[[:space:]]*#.*//' | \
        sed 's/^"\(.*\)"$/\1/' | \
        sed "s/^'\(.*\)'$/\1/"
}

# Export common variables
export GCP_PROJECT=$(get_tfvar "gcp_project")
export GCP_REGION=$(get_tfvar "gcp_region")
export GCP_ZONE=$(get_tfvar "gcp_zone")
export INSTANCE_NAME=$(get_tfvar "instance_name")

# Validate required variables
if [ -z "$GCP_PROJECT" ] || [ -z "$GCP_ZONE" ] || [ -z "$INSTANCE_NAME" ]; then
    echo "ERROR: Failed to read required variables from terraform.tfvars" >&2
    echo "Required: gcp_project, gcp_zone, instance_name" >&2
    echo "Found: GCP_PROJECT='$GCP_PROJECT' GCP_ZONE='$GCP_ZONE' INSTANCE_NAME='$INSTANCE_NAME'" >&2
    exit 1
fi
