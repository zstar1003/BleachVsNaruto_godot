# 死神 vs 火影：Mac 原技术栈运行核查

核查日期：2026-10-05；Godot 全阵容构建更新：2026-10-06。

## Godot 原生全阵容版

当前推荐双击根目录 `BleachVsNaruto-Godot.app`。0.2 开发版已接入 3.4 配置的 58 个角色／形态、37 个援助和 15 张地图，使用原 UI 素材、音频与逐帧动作，包含单人、组队、训练、观战和街机流程。应用内含 Godot 运行时，支持 Apple Silicon / Intel，无需安装 AIR。

构建通过 2,432 项基础检查、1,153 项角色／援助检查、310 项模式／UI 检查及 64 个 AI 场景，并完成导出与签名校验。已在导出应用中检查完整选人、援助、选地图和战斗显示。

完整操作、构建方法和与 Windows 原版尚存的差异见 [Godot 说明](godot/README.md)。当前尚未通过全角色逐帧对照验收，不能视为完全相同的原版复刻。

下文保留原 AIR 技术栈的核查记录。

## 使用的工程

- [OpenBleachVsNaruto](https://github.com/5DPLAY-Game-Studio/OpenBleachVsNaruto)：基于 3.4 调试版，默认入口是 `FighterTester` 对战测试器。
- [官方发行包 RELEASE_20260719](https://github.com/5DPLAY-Game-Studio/OpenBleachVsNaruto/releases/tag/RELEASE_20260719)：已保存并解包至 `research/release/swf_output`。
- [BleachVsNaruto](https://github.com/5DPLAY-Game-Studio/BleachVsNaruto)：当前 3.7 主工程；README 的 Mac OS 支持项尚未勾选。
- [BleachVsNaruto_FlexSDK](https://github.com/5DPLAY-Game-Studio/BleachVsNaruto_FlexSDK)：Flex 与 HARMAN AIR 的合并工具链，说明及预构建包面向 Windows。

## 本机环境与核查结果

- Apple Silicon（arm64），macOS 26.6.2，已安装 Java 17。
- 扫描了开放工程全部 182 个 `.as` 文件：未发现 `NativeProcess`、`ExtensionContext` 或 `HTMLLoader` 依赖；工程配置没有 ANE。
- 发行包包含 93 个 SWF、26 个 MP3、17 个 PNG；93 个 SWF 均能解压至其文件头声明的长度。
- 游戏配置 XML 均能解析，配置中检查到的 134 个资源路径全部存在。
- 本次复用官方已编译 SWF，保留 ActionScript 3、Flash 显示列表及 AIR 运行方式。
- 使用用户已同意许可的 HARMAN AIR SDK 51.4.1.1 Mac 版本。为本次运行和打包，提取了官方 SDK 中的 ADL、ADT、Mac 运行时及相关打包组件；此目录不是完整编译 SDK。

## 启动

直接双击项目根目录的 `BleachVsNaruto-Mac.app` 即可启动。应用内已包含 Mac AIR 运行时，无需另外安装共享运行时。

需要查看运行日志时，可以双击 `run-mac.command`，或在终端运行：

```bash
./run-mac.command
```

脚本默认使用 `research/tools/air-sdk/bin/adl`；可以通过 `AIR_SDK_PATH` 指定另一个 Mac AIR SDK 目录。游戏根目录作为 ADL 的第二个参数传入，确保 XML、角色、地图、音效使用正确的相对路径。

## 限制

目前默认启动的是角色对战测试器。正式版菜单、选人流程和其他模式需要分别验证或调整入口。

从 XFL 源素材重新编译还需要 Mac 版 Animate，并迁移原有 JSFL 发布配置、Windows 批处理脚本及工具。仅运行已编译发行包不需要 Animate 或旧版 Flash Builder。

## 实际运行结果

- 已使用官方 ADT 将发行包打包为 `BleachVsNaruto-Mac.app`，并完成本地临时签名。应用主程序和运行时均含 arm64 架构，应用及框架签名校验通过。
- 已打开 Mac 应用窗口，点击“开始测试”，进入一护与鸣人的练习场；角色、援助头像、地图、血条和动画正常显示。
- 默认 30 FPS 运行正常；试跑时将帧率设为 60，界面显示约 60 FPS。
- 自动化短按未能独立确认角色移动和跳跃；用户随后确认“能成功运行”。
- 本次验证复用了原项目已编译的 SWF，没有从 XFL/ActionScript 源文件重新构建游戏，也没有验证所有角色、地图或正式版菜单流程。

运行方式依据：[AIR ADL 文档](https://airsdk.dev/docs/building/air-debug-launcher)、[Mac SDK 安装说明](https://airsdk.dev/docs/basics/install/macos)。
