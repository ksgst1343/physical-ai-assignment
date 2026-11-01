#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/lerobot" >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "${script_dir}/.." && pwd)"
lerobot_dir="$(cd "$1" && pwd)"
patch_file="${project_dir}/patches/lerobot-v0.6.1-panda-gym-hil.patch"

if [[ "$(git -C "${lerobot_dir}" describe --tags --exact-match 2>/dev/null || true)" != "v0.6.1" ]]; then
  echo "LeRobot v0.6.1 is required." >&2
  exit 1
fi

git -C "${lerobot_dir}" apply --check "${patch_file}"
git -C "${lerobot_dir}" apply "${patch_file}"
echo "Applied ${patch_file}"
