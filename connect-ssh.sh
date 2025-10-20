#!/usr/bin/env bash
# Quick helper to SSH into the workstation using a public IP.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <public-ip>" >&2
  exit 1
fi

IP="$1"
USER="${SSH_USER:-ubuntu}"

exec ssh \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "${USER}@${IP}"
