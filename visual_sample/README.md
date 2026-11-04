# 家园岛 · 8×8 视觉样板

这是《汉堡物语》视觉改造的第一阶段样板。目标是先确认：

- 完整卡通兔子 Sprite 的比例与动画
- 统一光源、描边和色彩的独立透明素材
- 草地/沙地/海岸的拼接观感
- 普通状态隐藏网格
- 现有移动、采集、建造、搬动逻辑继续可用

**这只是小区域样板，不是完整地图改版。** 原 `map_prototype` 场景和热狗店场景都没有被覆盖。

## 启动

双击：

```text
F:\humger\启动视觉样板.bat
```

或：

```text
F:\humger\HamburgerStory\run_visual_sample.bat
```

## 操作

| 操作 | 按键 |
|---|---|
| 移动 | `WASD` / 方向键 |
| 采集 | `E` |
| 建造模式 | `B` |
| 选择物件 | 数字键 `1`-`3` 或鼠标点卡片 |
| 放置 | 建造模式下鼠标左键点地图 |
| 搬动物件 | 非建造模式下左键按住拖动，松开确认 |
| 取消 / 退出 | `Esc` |

## 样板内容

- 8×8 逻辑网格，28 个陆地格
- 完整兔子 Sprite：`idle` / `walk` × `down` / `up` / `side`
  - 待机 2 帧，走路 4 帧，一共 18 张独立透明 PNG
  - 左右方向通过水平翻转复用
- 独立素材：草丛、树、灌木/草丛、石头、木箱、2×1 桌子、椅子、树桩
- 草地/沙地/水面地块
- 普通状态完全隐藏网格
- 建造时显示网格和绿色/红色半透明放置预览
- E 采集、资源栏更新、树耗尽切换树桩
- 复用现有的网格占格、搬动、非法回滚和 UI 逻辑

## 素材来源

**没有裁切用户提供的资产图鉴。**

参考图只作为风格方向；所有 PNG 由：

```text
visual_sample/tools/generate_assets.py
```

从零绘制，输出到：

```text
assets/art_sample/
```

可重新生成：

```powershell
F:\deepseek\resources\runtime\primary-runtime\dependencies\python\python.exe `
  F:\humger\HamburgerStory\visual_sample\tools\generate_assets.py
```

素材检查图：

- `assets/art_sample/review_rabbit.png`
- `assets/art_sample/review_props.png`

## 测试

视觉样板逻辑验收（41 项）：

```powershell
$godot = "F:\humger\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
$proj = "F:\humger\HamburgerStory"
$env:APPDATA = "$proj\.userdata\roaming"
$env:LOCALAPPDATA = "$proj\.userdata\local"
& $godot --headless --path $proj res://visual_sample/tests/VisualSampleTest.tscn
```

视觉样板真实输入验收（10 项）：

```powershell
& $godot --path $proj res://visual_sample/tests/VisualSampleInputTest.tscn
```

现有地图逻辑回归仍为 69/69；热狗店回归仍为 89/89。

## 截图

- `visual_sample/screenshots/01_sample.png`：普通状态，隐藏网格
- `visual_sample/screenshots/02_sample_build.png`：建造预览
- `visual_sample/screenshots/03_sample_gather.png`：采集后的资源栏和树桩

## 当前边界

- 这是视觉样板，不是最终手绘资产
- HUD 继续复用现有样式，尚未做正式 UI 美术替换
- 样板只展示 1×1 / 2×1 家具；原地图的 3×3 放置逻辑未删除
- 没有扩展整张地图，没有制作员工、顾客、完整餐厅经营或联机

样板确认后，再按同一资产规范分批扩展整张地图。
