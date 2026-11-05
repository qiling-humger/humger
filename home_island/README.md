# 家园岛可玩原型 V1

独立于旧热狗店和旧地图原型的家园岛场景。当前使用 Stage 01/02 的
`assets/art_staging` 素材；兔子动画、家具和地形为 Stage 02 新制作。

## 启动

双击项目外的：

```text
F:\humger\启动家园岛V1.bat
```

或项目内：

```text
run_home_island.bat
```

## 操作

| 操作 | 键 |
| --- | --- |
| 移动 | WASD / 方向键 |
| 采集最近资源 | E |
| 进入/退出建造 | B / Esc |
| 选择建造物件 | 1–3 |
| 放置 | 建造模式下鼠标左键 |
| 搬动 | 非建造模式下按住已放置物件拖动，松开确认 |
| 取消搬动/退出建造 | Esc |
| 拆除 | 鼠标右键点击已放置物件 |
| 保存 | F5 |
| 读取 | F9 |

## 存档

- 位置：`user://home_island_v1_save.json`
- 每 2 秒自动保存；窗口关闭时再保存一次
- 启动时自动读取
- 保存内容：角色位置、木材/草/石头数量、每个资源节点剩余采集次数、已放置物件类型与位置

## 地图与资源

- 24×20 初始海岛，按参考布局包含水域、沙滩、草地、道路、花草、兔屋/餐厅/码头地标
- 13 棵树、3 丛草、9 块石头；地标区域占用网格
- 普通状态隐藏网格；建造模式显示网格
- 1×1 木箱/椅子，2×1 桌子
- 树/草/石头耗尽后视觉变淡、缩小并残留

## 测试

```powershell
F:\humger\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path F:\humger\HamburgerStory res://home_island/tests/HomeIslandTest.tscn
```

当前结果：**90/90**，覆盖 24×20 地图、地形分布、移动、动画睁眼、三种采集、枯竭、建造、红绿预览、多格、拆除、搬动回滚、手动存档、新实例重启恢复、可达性、异常存档防护，以及旋转、旋转占格/碰撞和旋转存档恢复。

截图：

- `screenshots/map_24x20.png`
- `screenshots/01_home_stage02.png`
- `screenshots/02_build_stage02.png`
- `screenshots/03_gather_stage02.png`

## 本阶段不做

- 餐厅、员工、顾客、完整经济系统
- 对兔屋/餐厅/码头地标做正式建筑与交互（当前只表达布局和占用）
