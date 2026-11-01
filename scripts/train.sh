#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/lerobot" >&2
  exit 2
fi

lerobot_dir="$(cd "$1" && pwd)"

source "${lerobot_dir}/.venv/bin/activate"
cd "${lerobot_dir}"
lerobot-train \
  --dataset.repo_id=ksgst1343/panda_pick_cube_v3 \
  --policy.type=act \
  --policy.repo_id=ksgst1343/panda_pick_cube_act_v3 \
  --output_dir=outputs/train/panda_act_10k_v3 \
  --job_name=panda_act_10k_v3 \
  --policy.device=cuda \
  --batch_size=8 \
  --steps=10000 \
  --wandb.enable=false
