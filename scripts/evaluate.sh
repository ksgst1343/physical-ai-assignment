#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 /path/to/lerobot [episodes]" >&2
  exit 2
fi

lerobot_dir="$(cd "$1" && pwd)"
episodes="${2:-10}"

source "${lerobot_dir}/.venv/bin/activate"
cd "${lerobot_dir}"
lerobot-eval \
  --policy.path=ksgst1343/panda_pick_cube_act_v3 \
  --env.type=gym_manipulator \
  --env.name=gym_hil \
  --env.task=PandaPickCubeKeyboard-v0 \
  --env.fps=10 \
  --env.processor.control_mode=keyboard \
  --env.processor.reset.control_time_s=120 \
  --env.processor.reset.terminate_on_success=true \
  --eval.n_episodes="${episodes}" \
  --eval.batch_size=1 \
  --output_dir="outputs/eval/panda_act_v3_${episodes}eps"
