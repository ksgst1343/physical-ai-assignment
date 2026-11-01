# Panda Pick Cube with ACT

MuJoCo 上の Panda ロボットアームに、キーボード操作で収集したデモデータからキューブの把持・持ち上げを学習させる Physical AI 最終課題です。データ収集、ACT（Action Chunking with Transformers）の学習、学習済みポリシーの評価までを LeRobot と `gym_hil` で実行します。

最終モデルは 10 エピソードの評価で 10/10 回成功しました。

## 公開成果物

- データセット: [ksgst1343/panda_pick_cube_v3](https://huggingface.co/datasets/ksgst1343/panda_pick_cube_v3)
- 学習済みモデル: [ksgst1343/panda_pick_cube_act_v3](https://huggingface.co/ksgst1343/panda_pick_cube_act_v3)
- 動画: [Youtube](https://www.youtube.com/watch?v=elGLhVowHAU)

GitHub には再現に必要な設定、コマンド、補助スクリプト、LeRobot への最小パッチだけを置いています。データセット本体、モデル重み、評価動画、学習出力はサイズが大きいため含めていません。

## 実験環境

実際に使用した環境は次のとおりです。

- ホスト OS: Windows 11
- Linux: WSL2 / Ubuntu 22.04
- GPU: NVIDIA GeForce RTX 2080 8 GB
- Python: 3.12
- LeRobot: v0.6.1 (`7e241bd6`)
- gym-hil: 0.1.14
- MuJoCo: 3.8.1
- PyTorch: 2.11.0+cu128
- torchvision: 0.26.0+cu128
- NumPy: 2.2.6
- PyAV: 15.1.0
- FFmpeg: 4.4.2

GPU を使わない場合は学習コマンドの `--policy.device=cuda` を `--policy.device=cpu` に変更できますが、学習時間は長くなります。

## リポジトリ構成

```text
.
├── configs/
│   └── pick_cube_record.json
├── patches/
│   └── lerobot-v0.6.1-panda-gym-hil.patch
├── scripts/
│   ├── apply_lerobot_patch.sh
│   ├── check_dataset.py
│   ├── evaluate.sh
│   ├── record.sh
│   └── train.sh
├── .gitattributes
├── .gitignore
└── README.md
```

## セットアップ

以下は WSL2 / Ubuntu 22.04 での手順です。

### 1. OS 側の依存関係

```bash
sudo apt update
sudo apt install -y git ffmpeg build-essential
```

LeRobot が使用する `uv` が未導入の場合は、[uv の公式手順](https://docs.astral.sh/uv/getting-started/installation/)でインストールします。

### 2. LeRobot を固定バージョンで準備

```bash
git clone https://github.com/huggingface/lerobot.git
cd lerobot
git checkout v0.6.1
uv sync --extra hilserl
source .venv/bin/activate
```

`hilserl` extra により `gym-hil>=0.1.14,<0.2.0` などの必要パッケージが入ります。

### 3. 本課題用パッチを適用

このリポジトリを LeRobot と同じ親ディレクトリへ clone した場合:

```bash
cd physical-ai-assignment
./scripts/apply_lerobot_patch.sh ../lerobot
```

パッチは LeRobot v0.6.1 を対象とし、次の互換処理を追加します。

- `gym_hil` の観測・Action feature と Gym ID の対応
- データ収録時の H.264 ストリーミングエンコード
- FFmpeg を使った収録動画の安全な結合
- エピソードごとにメタデータのキーが異なる場合の補完
- eval の複数カメラ画像の横連結
- eval 動画保存時の不要なバッチ次元の除去

適用後に仮想環境を有効化します。

```bash
cd ../lerobot
source .venv/bin/activate
```

### 4. Hugging Face 認証

公開済みモデルの評価だけなら認証は不要です。新しいデータセットやモデルを Hub に push する場合のみ、自分の環境でログインします。

```bash
huggingface-cli login
```

トークンは入力画面またはローカルの認証ストアに保存し、このリポジトリへ書き込まないでください。

## データ収集・テレオペレーション

設定は `configs/pick_cube_record.json` にあります。LeRobot の仮想環境を有効化した状態で、このリポジトリから実行します。

```bash
./scripts/record.sh ../lerobot
```

同等の直接コマンドは次のとおりです。

```bash
cd ../lerobot
python -m lerobot.rl.gym_manipulator \
  --config_path ../physical-ai-assignment/configs/pick_cube_record.json
```

主な操作は次のとおりです。

- 矢印キー: XY 方向移動
- Shift: Z 方向移動
- Right Ctrl: 今回の MuJoCo 環境では物理的にグリッパーを閉じる方向
- Left Ctrl: 今回の MuJoCo 環境では物理的にグリッパーを開く方向
- Enter: 成功としてエピソード終了
- Backspace: 失敗としてエピソード終了
- Space: intervention の開始・停止
- Esc: 終了

`gym_hil` 内部のコマンド名と、今回使用した Panda MuJoCo モデル上の実際の開閉方向が逆に見えるため、画面上の物理動作を確認してから収録してください。最終データでは Right Ctrl に対応する `action[3] = 2` が物理的な close でした。

収録後のフレーム数と gripper action 分布は次で確認できます。

```bash
python scripts/check_dataset.py ksgst1343/panda_pick_cube_v3
```

## ACT の学習

```bash
./scripts/train.sh ../lerobot
```

実際に使用したコマンドは次のとおりです。

```bash
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
```

学習結果は `outputs/` に作られ、モデルは指定した Hugging Face リポジトリへ push されます。`outputs/` と重みファイルは `.gitignore` の対象です。

## 評価・推論

10 エピソード評価:

```bash
./scripts/evaluate.sh ../lerobot 10
```

実際に使用したコマンドは次のとおりです。

```bash
lerobot-eval \
  --policy.path=ksgst1343/panda_pick_cube_act_v3 \
  --env.type=gym_manipulator \
  --env.name=gym_hil \
  --env.task=PandaPickCubeKeyboard-v0 \
  --env.fps=10 \
  --env.processor.control_mode=keyboard \
  --env.processor.reset.control_time_s=120 \
  --env.processor.reset.terminate_on_success=true \
  --eval.n_episodes=10 \
  --eval.batch_size=1 \
  --output_dir=outputs/eval/panda_act_v3_10eps
```

評価動画は `outputs/eval/panda_act_v3_10eps/` 以下へ保存されます。評価時は success 表示だけでなく、reward と動画の実動作も確認しました。

## 実験条件と結果

- タスク: `PandaPickCubeKeyboard-v0`
- 制御周期: 10 FPS
- 観測: 18 次元 state、front camera、wrist camera
- Action: 4 次元（X、Y、Z、gripper）
- 最終データ: 30 エピソード、1,118 frames
- エピソード長: 35〜41 frames
- 物理的な gripper close (`action[3] = 2`): 437 frames（39.1%）
- Policy: ACT / ResNet18 image encoder
- 学習: 10,000 steps、batch size 8、CUDA
- 最終評価: 10/10 成功

初期データには 1 frame だけの異常エピソードが混在し、gripper close の比率も約 8.6% でした。そのデータで学習したモデルは gripper action がほぼ `1.0` に固定され、把持できませんでした。収録方法を見直して異常エピソードをなくし、close action を 39.1% まで増やしたことで、再学習後のモデルは適切なタイミングで `action[3]` を約 `2.0` へ変化させ、把持と持ち上げに成功しました。

## 学習済みモデルとデータセットの扱い

- GitHub: 実行コード、設定、パッチ、手順のみ
- Hugging Face Dataset: `ksgst1343/panda_pick_cube_v3`
- Hugging Face Model: `ksgst1343/panda_pick_cube_act_v3`
- ローカル生成物: `outputs/`、Hugging Face cache、動画、Parquet、モデル重み

再現時は Hugging Face から必要なデータとモデルが自動取得されます。大容量バイナリを GitHub へ追加しないでください。

## AI の使用方法

人間のテレオペレーションを教師データとして ACT を学習し、front / wrist 画像とロボット状態から次の 4 次元 action を推論しました。生成 AI は環境構築、エラー調査、データ統計の確認、ドキュメント整理の補助に使用し、最終的なコマンド、データ分布、評価結果はローカル環境で確認しました。

## 注意事項

- パッチは LeRobot v0.6.1 専用です。別バージョンでは `git apply --check` が失敗する可能性があります。
- `outputs/`、データセット、モデル重み、Hugging Face token、キャッシュは commit しないでください。
- 公開前に `git status` と秘密情報スキャンを確認してください。
- 評価終了後にネイティブライブラリ由来の segmentation fault が表示される場合がありましたが、`End of eval` 後で、評価結果と動画の保存完了を確認しています。
