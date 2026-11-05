# home_island 共享核心

V1 的 HomeIsland 场景、数据和美术资源已删除。这里只保留新手关与 V2 测试场景共用的代码：

```text
home_island/
├─ core/       # 网格、地形、放置、库存、锚点、UI 基础
├─ scripts/    # 共享游戏协调器、兔子、放置控制器
└─ README.md
```

当前主场景是：

```text
res://tutorial/TutorialLevel.tscn
```

新手关测试：

```powershell
F:\humger\tools\godot\Godot_v4.7.2-stable_win64_console.exe `
  --headless --path F:\humger\HamburgerStory `
  res://tutorial/tests/TutorialLogicTest.tscn
```

结果：**28 / 28**。

V2 风格测试场景：

```text
res://home_island_v2_test/HomeIslandV2Test.tscn
```

它仍使用 `assets/art_style_v2_test/` 的 16×12 小样板，不是主初始岛。

## 注意

- 不要再从 `home_island/data` 或 `assets/art_staging` 加载资源；这两个 V1 目录已删除。
- 共享代码里的默认路径已指向 `tutorial/data/tutorial_*.json`。
