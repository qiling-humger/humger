# 汉堡物语 · 家园岛可玩原型 V1

使用 **Godot 4.7.2** 的 45° 斜俯视 2D 卡通家园岛原型。

当前项目位置：`F:\humger\HamburgerStory`
根目录快捷启动：`F:\humger\启动家园岛V1.bat`

## 启动

双击：

```text
F:\humger\启动家园岛V1.bat
```

或项目内：

```text
run_home_island.bat
```

也可以打开 `project.godot` 后按 F5；主场景已指向 `home_island/HomeIsland.tscn`。

## 操作

| 操作 | 按键 |
|---|---|
| 移动 | `WASD` / 方向键 |
| 采集最近资源 | `E` |
| 建造 / 退出 | `B` / `Esc` |
| 选择建造物件 | `1`–`3` |
| 放置 | 建造模式下鼠标左键 |
| 搬动物件 | 非建造模式下拖动已放置物件 |
| 拆除 | 鼠标右键点击物件 |
| 保存 / 读取 | `F5` / `F9` |

## 当前内容

- 24×20 初始海岛，按参考布局包含水域、沙滩、草地、道路、花草与地标
- 兔子四向移动；待机/行走动画
- 树采木材、草丛采草、石头采石材
- 资源耗尽状态
- 1×1 / 2×1 网格建造、搬动、取消、右键拆除
- 水面/重叠/边界禁止放置，绿色/红色预览
- 自动保存与启动恢复：角色位置、库存、资源剩余次数、物件位置

## 目录

```text
home_island/
├─ HomeIsland.tscn
├─ data/
│  ├─ home_island_config.json
│  └─ home_asset_catalog.json
├─ scripts/
│  ├─ home_island_game.gd
│  ├─ home_island_rabbit.gd
│  ├─ home_island_placement.gd
│  └─ home_island_ui.gd
├─ core/                 # 共享网格、兔子、放置、地形、UI 基础
├─ tests/
│  ├─ HomeIslandTest.tscn
│  ├─ home_island_test.gd
│  ├─ HomeIslandCapture.tscn
│  └─ capture_home_island_runner.gd
└─ screenshots/
```

## 测试

```powershell
$godot = "F:\humger\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
& $godot --headless --path F:\humger\HamburgerStory res://home_island/tests/HomeIslandTest.tscn
```

当前结果：**61 / 61**。

## 说明

- 旧热狗店、`map_prototype`、`visual_sample` 已移除，共享实现迁移到 `home_island/core/`。
- 美术已切到 Stage 01/02 素材：兔子动画、家具和地形在 `assets/art_staging/stage_02/`，树/灌木/石头在 `assets/art_staging/stage_01_base/`。
- 旧 `assets/art_sample` 过渡素材已移除。
- 本阶段不做餐厅、员工、顾客、完整经济系统或整图扩张。
- 中文字体使用 Noto Sans SC，许可见 `assets/fonts/OFL.txt`。
