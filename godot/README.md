# 死神 vs 火影 3.4：Godot 原生移植

当前为 **0.2 全阵容开发版**，使用 Godot 4.7.2 / GDScript，在 macOS 原生运行。应用包含运行时与转换后的素材，无需安装 AIR 或 Godot。

## 启动

双击仓库根目录的 `BleachVsNaruto-Godot.app`。这是同时支持 Apple Silicon 和 Intel 的 Universal Mac 应用。0.1 双角色备份位于 `build/BleachVsNaruto-Godot-0.1.app`。

编辑工程：用 Godot 打开 `project.godot`，按 F5。根目录 `run-godot.command` 可启动开发工程。

## 本轮已移植

- 原配置中的全部 **58 个角色／形态、37 个援助、15 张地图**；变身、隐藏形态、随机选人和平台。
- 角色和援助的原图像、音频、逐帧动作、攻击区域、受击区域和脚本分支；共有 6,526 个角色时间轴脚本帧和 311 个援助时间轴脚本帧。
- 原版标题、选人、选地图、设置、按键设置、暂停、出招表、街机操作教学、胜利、继续、Game Over 界面的素材及字体；战斗 HUD、回合／KO／Perfect、连击数字和组队头像。
- 单人／组队、本地双人、对战 CPU、电脑观战、训练、原配置的八关街机流程；组队换人、回血、气继承、胜负回合、原计分规则。
- 原 AI 的 17 个决策函数、每个角色的攻击距离配置、六档难度。
- 49 个原特效动画、52 个效果定义、27 个特效声音；原 BGM、角色时间轴音频、菜单音效与残影。

## 操作

| 动作 | P1 | P2 |
| --- | --- | --- |
| 移动／上／防御 | WASD | 方向键 |
| 攻击 | J | 1 / 小键盘 1 |
| 跳跃 | K | 2 / 小键盘 2 |
| 冲刺 | L | 3 / 小键盘 3 |
| 技能 | U | 4 / 小键盘 4 |
| 必杀 | I | 5 / 小键盘 5 |
| 援助／受击特殊脱身 | O | 6 / 小键盘 6 |

上下方向与攻击、技能、必杀组合沿用原版。J+K、上/下+J+K 触发角色可用的变身，H 是额外的测试快捷键；选人时 I / 5 或右键切换配置中的隐藏形态。设置页提供原版 SET ALL / SET DEFAULT / APPLY / CANCEL 按键流程。

Esc 暂停，Tab 出招表，R 重开当前对局，M 静音，F3 显示判定框。

## 验证与尚未达到的验收

自动检查包含：2,432 项基础战斗与资源检查、1,153 项全角色／援助烟雾检查、310 项模式与 UI 检查、64 个原 AI 对战场景。构建器还检查脚本错误、Universal Mac 导出和签名。

**这不是已经通过逐帧验收的 Windows 原版一比一复刻。** 全部配置角色和素材已接入，但烟雾检查只证明执行覆盖与运行稳定，不证明每个招式的伤害、追踪、抓取、判定、取消窗口和 AI 行为完全相同。仍需与原 AIR 版本进行逐项对照：

- 部分显示树的嵌套子动画、动态遮罩及颜色变换；中文字体在 macOS 使用替代字体；菜单与页面过渡的缓动还未全部对齐。
- 攻击道具物理、特殊受击效果、慢动作和角色初始化的兼容语义；相机、击停、音频混音仍需实测校准。
- 全角色复杂输入分支和变身前后状态继承，以及街机全部结算路径的长期回归。

## 构建与素材转换

```sh
python3 tools/build-godot.py
```

构建器依次导入资源、执行四组检查、导出自包含 Mac 应用并验证签名。需要 Godot 4.7.2 和对应 Mac 导出模板。

完整重新转换 3.4 原发行素材：

```sh
python3 tools/build-godot.py --import-full
```

需要本地 `research/release/swf_output`、`research/OpenBleachVsNaruto`、FFDec 26.3.0、Java 17、Python、Pillow、NumPy、FFmpeg。转换只读原 SWF，生成 PNG、JSON 与音频；保留来源哈希、注册点、矩阵和碰撞区域。`assets/full/catalog.json` 是全量清单，`assets/ui/manifest.json` 是原 UI 的显示树。源 SWF 与 AIR 不参与 Godot 应用运行。

## 来源

- [OpenBleachVsNaruto](https://github.com/5DPLAY-Game-Studio/OpenBleachVsNaruto)：3.4 源码与发行素材。
- [JPEXS FFDec](https://github.com/jindrapetrik/jpexs-decompiler)：素材与时间轴导出。
- [Godot](https://godotengine.org/)：原生运行时。

人物、图像、音乐与声音沿用原素材，本项目不声明这些内容为新创作。
