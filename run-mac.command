#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")" && pwd)"
sdk_dir="${AIR_SDK_PATH:-$project_dir/research/tools/air-sdk}"
game_dir="$project_dir/research/release/swf_output"

if [[ ! -x "$sdk_dir/bin/adl" ]]; then
  echo "找不到 Mac AIR SDK：$sdk_dir/bin/adl" >&2
  echo "请将 AIR_SDK_PATH 指向已解压的 Mac AIR SDK。" >&2
  exit 2
fi
if [[ ! -s "$game_dir/FighterTester.swf" ]]; then
  echo "找不到已解包的游戏主程序：$game_dir/FighterTester.swf" >&2
  exit 3
fi

cd "$game_dir"
exec "$sdk_dir/bin/adl" "$game_dir/META-INF/AIR/application.xml" "$game_dir"
