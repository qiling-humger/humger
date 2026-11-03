# 《汉堡物语》调试指南

## 1. 打开编辑器

双击项目目录里的 `open_editor.bat`。

它会沿用项目内 `.userdata` 作为 Godot 缓存目录，避免本机默认 AppData 目录权限问题。

也可以命令行：

```powershell
cd F:\humger\HamburgerStory
.\open_editor.bat
```

打开编辑器后：

- 主场景：`res://scenes/Main.tscn`
- 按 `F5` 运行整个项目。
- 按 `F6` 只运行当前打开的场景（调试 `tests/TestRunner.tscn` 时很有用）。
- 运行后如果游戏窗口被编辑器挡住，按 `Alt + Tab` 切过去。

## 2. 最常用的调试动作

### 断点

1. 打开一个 `.gd` 脚本。
2. 点击某一行左侧行号旁的空白处，出现红点就是断点。
3. 按 F5 启动游戏。
4. 游戏执行到这一行时会暂停，底部 `Debugger` 面板出现。
5. 可以在 `Stack Frames` / `Variables` 查看当前函数参数、局部变量、节点属性。
6. 用调试栏按钮继续、单步跳过、单步进入、单步跳出。常用快捷键：
   - `F10`：单步跳过
   - `F11`：单步进入
   - `Shift + F11`：单步跳出
   - 如果快捷键和你的编辑器布局不一致，以 `Debug` 菜单里的实际条目为准。

### 打印

在怀疑的位置临时加：

```gdscript
print("当前金币: ", economy_system.coins)
print("订单: ", order)
push_warning("这里走到不该走的分支了")
push_error("订单数据为空")
```

游戏运行时，`Output` 面板会实时显示。发布版本前记得清理。

### 断言

```gdscript
assert(not order.is_empty(), "订单不能为空")
```

断言失败会在调试器中直接停住，适合检查“理论上绝不该为空”的状态。

### 远程场景树

游戏运行中，编辑器 `Scene` 面板切到 **Remote**：

- 可以实时查看 `GameManager`、`Entities`、`UI` 下所有节点。
- 可以选中节点，在 Inspector 里改属性，立刻观察画面变化。
- 可以查看当前场景树结构，确认顾客、烤架、组装台等节点是否存在。

### 暂停 / 单帧 / 性能

`Debug` 菜单和 `Debugger` 面板里还有：

- 暂停、继续、单帧步进
- `Errors`：脚本报错、逻辑错误
- `Profiler`：每帧耗时
- `Monitors`：FPS、对象数、内存
- `Video RAM`：显存占用

## 3. 这个项目里该在哪里下断点

### 完整流程入口

`scripts/game_manager.gd`

- `start_shift()`：开始营业、重置系统、生成第一位顾客。
- `deliver_hotdog()`：交付校验、奖励/惩罚、顾客离店的入口。
- `end_shift()`：结算数据、评级和结束条件。
- `_on_customer_left()`：顾客超时或离店的处理。

### 烹饪质量

`scripts/systems/cooking_system.gd`

- `_process()`：每根烤肠的 `elapsed` 随时间增长。
- `take_best()`：取出“火候最好”的那一根。
- `set_slot_time()`：测试时快速把烤肠设到某个时间，适合验证火候状态。

火候阈值在 `data/game_config.json` 的 `cooking.states` 里。

### 订单与顾客

- `scripts/systems/order_system.gd`
  - `generate_order()`：随机订单生成。
  - `validate_order()`：火候/肠数/酱料是否正确。
- `scripts/systems/customer_queue.gd`
  - `spawn_customer_now()`：顾客生成、订单绑定、入队。
  - `dismiss_front()`：顾客被交付、错误离店。
- `scripts/entities/customer.gd`
  - `_process()`：耐心倒计时和超时触发。
  - `patience_ratio()`：HUD 耐心条的数据源。

### 经济

`scripts/systems/economy_system.gd`

- `reward_order()`：正确交付，金币、小费、满意度、统计。
- `penalize_wrong()`：错误交付。
- `penalize_timeout()`：顾客耐心耗尽。

想查“为什么金币不对”，就在这几个函数里看 `order`、`quality_id`、`patience_ratio` 的实参。

### 交互

`scripts/systems/interaction_system.gd`

- `_process()`：找最近设备、维护高亮。
- `try_interact()`：按 E 时真正调用设备交互。

如果某个设备“按 E 没反应”：

1. 断在 `interaction_system.gd` 的 `_process()`。
2. 看 `current_station` 是不是目标设备。
3. 看 `current_prompt` 里的 `enabled`。
4. 看 `Main.tscn` 里该设备的 `interaction_offset` / `interaction_radius` 和玩家距离。

### 玩家移动

`scripts/entities/player.gd`

- `_physics_process()`：输入方向、移动、朝向。
- `_can_stand()`：菱形地面边界和设备阻挡。
- 如果走不进某个区域，优先看 `footprint` 和障碍矩形。

### 场景布局

`scenes/Main.tscn`

- 所有设备的位置、`footprint`、`interaction_offset`、`label_offset` 都在这里。
- 改完位置后，记得确认交互点仍在可达区域内。

### UI

- `scripts/ui/hud.gd`：HUD 每秒重绘，数值直接读系统状态。
- `scripts/ui/ui_manager.gd`：HUD、标题、暂停、结算的显示切换。
- 如果数值变了但界面没变，先看 `hud.gd:_draw()` 是否读的是同一个字段。

## 4. 想快速复现一场完整订单

直接运行测试场景：

- 在编辑器中打开 `tests/TestRunner.tscn`，按 `F6`。
- 它会实例化 `Main.tscn`，自动走：

```text
开始营业 → 自动到店 → 取生肠 → 烤制 → 组装 → 加酱 → 交付
→ 错误交付 → 超时 → 暂停 → 结算 → 重开 → 连续订单 → 自动结束
```

调试时可以把断点下在任何被测试调用的函数里。

无头快速回归：

```powershell
cd F:\humger\HamburgerStory
..\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/TestRunner.tscn
```

## 5. 常用验收命令

窗口模式完整验收（含鼠标点击）：

```powershell
cd F:\humger\HamburgerStory
.\run_tests.bat
```

实机截图：

```powershell
cd F:\humger\HamburgerStory
$env:APPDATA = "$PWD\.userdata\roaming"
$env:LOCALAPPDATA = "$PWD\.userdata\local"
..\tools\godot\Godot_v4.7.2-stable_win64_console.exe --path . res://tests/CaptureRunner.tscn
```

## 6. 调试中容易踩的坑

- 游戏处于暂停或结算时，`get_tree().paused = true`，很多节点不处理逻辑。先恢复流程再继续测试。
- 改了 `data/game_config.json` 后不用重新导入，但当前已经加载的旧配置不会热更新；重新按 F5。
- 改了 `.tscn` 节点位置后，玩家可能走不到交互点。用 F5 实际走过去，或看 `TestRunner` 的全设备可达性检查。
- 无头模式不会处理 GUI 鼠标点击，这是 Godot DisplayServer 的限制，不代表按钮坏了。
- 项目里的启动和测试脚本会设置 `APPDATA/LOCALAPPDATA`，直接双击 Godot 打开项目可能会遇到本机缓存目录权限问题，所以优先用 `open_editor.bat`。
