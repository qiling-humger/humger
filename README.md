# 汉堡物语 · 初始岛 V2 新手关

Godot 4.7.2 的 45° 斜俯视 2D 卡通初始岛。主场景已经切到 **Simple Cartoon V2 素材 + 24×20 新手关**，V1 的美术资源和 V1 HomeIsland 场景/测试已移除。

项目位置：`F:\humger\HamburgerStory`

## 启动

双击：

```text
F:\humger\启动初始岛.bat
```

或：

```text
F:\humger\启动新手关.bat
```

也可以打开 `project.godot` 后按 F5；主场景是：

```text
res://tutorial/TutorialLevel.tscn
```

## 操作

| 操作 | 按键 |
|---|---|
| 移动 | `WASD` / 方向键 |
| 采集 / 对话 / 做菜 / 交付 / 睡觉 | `E` |
| 建造 / 退出 | `B` / `Esc` |
| 选择建造物件 | `1`–`3` |
| 放置 | 建造模式下鼠标左键 |
| 保存 / 读取 | `F5` / `F9` |
| 提示 | `H` |

## 当前内容

- 24×20 初始岛，V2 草地、树木、石头、兔子素材
- 参考布局的水域、沙滩、草地、道路、花草、兔屋/餐厅/码头区域
- 五天新手关：第 1 天采集泥土/材料 → 建餐厅 → 进入餐厅内部；之后是顾客、员工送餐、大胡萝卜和造船
- 餐厅是独立室内场景：`res://tutorial/RestaurantInterior.tscn`（E 进入/返回）
- 网格建造、搬动、旋转、拆除、绿红预览
- 自动保存/启动恢复

## 目录

```text
tutorial/
├─ TutorialLevel.tscn        # 主场景
├─ data/                     # 24×20 V2 地图、资源、建筑定义
├─ scripts/                  # tutorial_game / actor / hud
├─ tests/                    # 逻辑测试与截图
├─ assets/placeholder/       # 餐厅/小船/草丛占位
└─ screenshots/

home_island/
├─ core/                     # 共享网格、地形、放置、库存、锚点
├─ scripts/                  # 共享游戏/兔子/放置控制器
└─ README.md                 # 共享核心说明
```

## 测试

```powershell
$godot = "F:\humger\tools\godot\Godot_v4.7.2-stable_win64_console.exe"

# 新手关逻辑（含 24×20 地图布局）
& $godot --headless --path F:\humger\HamburgerStory `
  res://tutorial/tests/TutorialLogicTest.tscn

# V2 风格测试场景
& $godot --headless --path F:\humger\HamburgerStory `
  res://home_island_v2_test/tests/V2StyleTest.tscn
```

当前结果：

- 新手关逻辑：**24 / 24**
- V2 风格测试：**19 / 19**

## 说明

- V1 的 `assets/art_staging`、V1 HomeIsland 场景、配置、测试和截图已删除。
- 当前只使用 `assets/art_style_v2_test/` 的 V2 素材和 `tutorial/assets/placeholder/` 占位。
- 餐厅/顾客/员工/小船是教学关占位表现，不改变 V2 美术风格。
- 中文字体使用 Noto Sans SC，许可见 `assets/fonts/OFL.txt`。
