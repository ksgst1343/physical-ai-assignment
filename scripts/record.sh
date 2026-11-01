#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/lerobot" >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "${script_dir}/.." && pwd)"
lerobot_dir="$(cd "$1" && pwd)"

source "${lerobot_dir}/.venv/bin/activate"
cd "${lerobot_dir}"
python -m lerobot.rl.gym_manipulator \
  --config_path "${project_dir}/configs/pick_cube_record.json"
