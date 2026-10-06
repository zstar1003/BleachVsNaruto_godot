# BleachVsNaruto_godot

《死神 vs 火影》3.4 的 Godot 原生移植工程，当前版本为 **0.2 全阵容开发版**。使用 Godot 4.7.2 / GDScript，保留原版角色、地图、声音与 UI 素材。

**目前尚未通过与 Windows 原版的逐帧一致性验收。** 全配置内容已经接入，复杂招式行为、部分特效、动态遮罩、字体及 UI 过渡仍有差异。具体范围见 [工程说明](godot/README.md)。

## 下载与运行

[下载 v0.2.0 Mac 应用](https://github.com/zstar1003/BleachVsNaruto_godot/releases/tag/v0.2.0)。解压后打开 `BleachVsNaruto-Godot.app`；同时支持 Apple Silicon 和 Intel，内含运行时，无需安装 Godot 或 AIR。应用使用本地临时签名，未做 Apple 公证。

开发运行：克隆仓库，在 Godot 中导入 `godot/project.godot`，等待素材导入后按 F5。工程包含转换后的 PNG、JSON、音频；运行无需原 SWF、Java 或 AIR SDK。

```sh
git clone https://github.com/zstar1003/BleachVsNaruto_godot.git
```

素材较多，首次克隆与 Godot 导入需要一些时间。

## 当前内容

- 58 个角色／形态、37 个援助、15 张地图。
- 原角色逐帧动作、碰撞数据、脚本分支、音频和变身；原 AI 决策函数及六档难度。
- 原标题、选人、选地图、设置、按键设置、暂停、出招表、操作教学、胜利与继续界面素材，以及战斗 HUD。
- 单人／组队、本地双人、对战 CPU、电脑观战、训练和八关街机流程。

P1 使用 WASD / J K L U I O；P2 使用方向键 / 1 2 3 4 5 6，支持小键盘。Esc 暂停，Tab 查看出招表。完整操作和隐藏形态入口见 [Godot README](godot/README.md)。

## 构建与验证

Mac 构建需安装 Godot 4.7.2、对应导出模板及 Python 3；当前构建脚本默认使用 `/Applications/Godot.app`。

```sh
python3 tools/build-godot.py
```

脚本导入素材、执行四组检查、导出 Mac 应用并验证签名。当前构建通过 2,432 项基础检查、1,153 项角色／援助烟雾检查、310 项模式／UI 检查和 64 个 AI 场景；这些检查不等于原版行为一致性验收。详细记录见 [验证报告](docs/godot-0.2-verification.json)。

素材重新转换流程、依赖与本地原文件路径见 [工程说明](godot/README.md#构建与素材转换)。`research/` 下载、SDK、转换缓存和本地签名凭据不包含在仓库内。

## 来源

原游戏代码与发行素材来自 [5DPLAY-Game-Studio/OpenBleachVsNaruto](https://github.com/5DPLAY-Game-Studio/OpenBleachVsNaruto)，转换工具使用 [JPEXS FFDec](https://github.com/jindrapetrik/jpexs-decompiler)。人物、图像、音乐与声音沿用原素材，相关权利归原权利人。本仓库不声明这些内容为原创，也不为第三方素材授予新的许可。

[来源说明](ATTRIBUTION.md) · [Godot 工程说明](godot/README.md) · [原 AIR 运行核查](MAC-RUN.md)
