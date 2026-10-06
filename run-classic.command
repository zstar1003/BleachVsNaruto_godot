#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")" && pwd)"
sdk_dir="${AIR_SDK_PATH:-$project_dir/research/tools/air-sdk}"
game_dir="$project_dir/build/classic"
if [[ ! -x "$sdk_dir/bin/adl" || ! -s "$game_dir/ClassicMain.swf" ]]; then
    echo "缺少调试运行所需的 Mac AIR SDK 或构建文件。" >&2
    echo "日常游玩请直接打开 BleachVsNaruto-3.4-Mac.app。" >&2
    exit 2
fi
cd "$game_dir"
exec "$sdk_dir/bin/adl" "$game_dir/application.xml" "$game_dir"
