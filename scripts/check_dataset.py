#!/usr/bin/env python3
import argparse
from collections import defaultdict

import numpy as np
from lerobot.datasets.lerobot_dataset import LeRobotDataset


def main() -> None:
    parser = argparse.ArgumentParser(description="Summarize Panda Pick Cube demonstration episodes.")
    parser.add_argument("repo_id", nargs="?", default="ksgst1343/panda_pick_cube_v3")
    args = parser.parse_args()

    dataset = LeRobotDataset(args.repo_id)
    stats = defaultdict(lambda: {"frames": 0, "stay": 0, "close": 0, "open": 0})

    for index in range(len(dataset)):
        sample = dataset[index]
        episode = int(np.asarray(sample["episode_index"]))
        gripper = float(np.asarray(sample["action"])[-1])
        stats[episode]["frames"] += 1
        if gripper > 1.5:
            stats[episode]["close"] += 1
        elif gripper < 0.5:
            stats[episode]["open"] += 1
        else:
            stats[episode]["stay"] += 1

    total_close = sum(item["close"] for item in stats.values())
    print(f"total frames: {len(dataset)}")
    print(f"num episodes: {len(stats)}\n")

    for episode in sorted(stats):
        item = stats[episode]
        print(
            f"episode {episode:02d}: "
            f"frames={item['frames']:3d}, "
            f"stay={item['stay']:3d}, "
            f"physical_close(2)={item['close']:3d}, "
            f"physical_open(0)={item['open']:3d}"
        )

    close_ratio = total_close / len(dataset) if len(dataset) else 0.0
    one_frame_episodes = [episode for episode, item in stats.items() if item["frames"] <= 1]
    print(f"\ntotal physical close frames: {total_close}")
    print(f"physical close ratio: {close_ratio:.4f}")
    print(f"1-frame episodes: {one_frame_episodes}")


if __name__ == "__main__":
    main()
