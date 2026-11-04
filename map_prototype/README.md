# 家园岛 · 地图原型

这是《汉堡物语》第一版可运行地图原型，按 Notion《汉堡物语 · 地图系统与基础资源设计》实现。
它**独立于热狗店 MVP**，不覆盖、不删除原有场景和脚本。

## 怎么启动

在项目目录双击：

```text
F:\humger\启动地图原型.bat
```

或直接运行：

```text
F:\humger\HamburgerStory\run_map_prototype.bat
```

也可以在 Godot 里打开 `res://map_prototype/MapPrototype.tscn` 后按 F6。

## 操作

| 操作 | 按键 |
|---|---|
| 移动小白兔 | `W` `A` `S` `D` / 方向键 |
| 采集附近资源 | `E` |
| 进入 / 退出建造模式 | `B` |
| 选择建造物 | 鼠标点右侧卡片，或数字键 `1`-`4` |
| 放置物件 | 建造模式下鼠标左键点地图 |
| 搬动已放置物件 | 非建造模式下，左键按住物件拖到新格，松开确认 |
| 取消 / 退出 | `Esc` |

## 第一阶段已实现

- 45° 菱形等距视角，逻辑网格 **24×18**，显示 Tile **64×32**
- 家园岛：草地、沙滩、中央建造空地、外围海水与不可通行海岸
- 玩家移动、逻辑格碰撞、镜头平滑跟随与地图边界限制
- 22 个资源节点：小树、草丛、落叶堆、石块
- `E` 采集，资源次数耗尽后变成残迹，顶部资源栏实时增加
- 顶部资源栏：木材、草、树叶、石头、泥土、金币，开局全为 0
- `B` 建造模式：1×1、2×1、2×2、3×3 四种 footprint
- 放置预览绿色/红色、水面/边界/占格/玩家脚下检测
- 已放置物件拖动搬动，非法落点自动回滚
- 建造面板、交互提示、`+N` 资源提示
- 全部美术为代码绘制的卡通占位图形，无外部美术依赖

## 第一阶段暂不包含

- 员工、顾客、完整餐厅经营
- 完整菜谱、经济结算、营业时间
- 联机
- 泥土挖掘、水壶取水（资源栏已预留，逻辑未接入）
- 正式美术替换、存档

## 文件结构

```text
map_prototype/
├─ MapPrototype.tscn            独立入口场景
├─ data/island_config.json      地图/资源/物件配置
├─ scripts/
│  ├─ island_grid.gd            逻辑网格、坐标、占地、阻挡
│  ├─ island_map.gd             地形、海岸线、网格、装饰
│  ├─ water_background.gd       海水和波纹
│  ├─ rabbit_player.gd          小白兔移动/碰撞/镜头
│  ├─ island_resource_node.gd   资源节点与采集
│  ├─ resource_inventory.gd     资源库存
│  ├─ placeable_object.gd       多格物件逻辑与绘制
│  ├─ placement_controller.gd   建造/预览/搬动
│  ├─ map_ui.gd                 资源栏、建造面板、提示
│  └─ map_game.gd               总协调器
├─ tests/                       无头逻辑测试 + 窗口输入测试 + 截图
└─ screenshots/                 实际运行截图
```

## 测试

无头逻辑验收（69 项）：

```powershell
$godot = "F:\humger\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
$proj = "F:\humger\HamburgerStory"
$env:APPDATA = "$proj\.userdata\roaming"
$env:LOCALAPPDATA = "$proj\.userdata\local"
& $godot --headless --path $proj res://map_prototype/tests/MapPrototypeTest.tscn
```

窗口真实输入验收（11 项，测试 E/B、鼠标选卡、鼠标放置、鼠标拖动）：

```powershell
& $godot --path $proj res://map_prototype/tests/MapInputTest.tscn
```

截图：

```powershell
& $godot --path $proj res://map_prototype/tests/CaptureMap.tscn
```
