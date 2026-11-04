# Simple Cartoon Isometric V2 · 第一轮风格测试

这是独立的风格验证场景，不覆盖正式 `home_island` 的场景、配置和素材。

## 测试素材

目录：`assets/art_style_v2_test/`

1. 草地：`terrain/transparent/grass.png`
2. 树木：`props/transparent/tree.png`
3. 石头：`props/transparent/rock.png`
4. 木桌：`furniture/transparent/table.png`
5. 兔子：`rabbit/frames/`（沿用当前 17 帧动画，未重做角色身份）

原始 AI 图在各自 `source/` 目录，风格对照图在 `preview/v2_assets_contact.jpg`。

## 场景

- `HomeIslandV2Test.tscn`
- 16×12 水面+草地测试岛
- 普通状态隐藏建造网格
- 只包含 5 种测试素材；没有沙地、草丛、其他家具
- 兔子仍使用现有方向动画系统
- 正式 `home_island` 未被替换

## 测试

```powershell
& F:\humger\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path F:\humger\HamburgerStory res://home_island_v2_test/tests/V2StyleTest.tscn
```

结果：**19/19**。

截图：

- 修复前：`screenshots/before_normal.png`、`before_build.png`
- 修复后普通态：`screenshots/05_normal_grounded.png`
- 修复后旋转预览：`screenshots/06_build_rotated.png`
- 修复后旋转落位：`screenshots/07_placed_rotated.png`

## 本轮场景/建造修复

- 底部锚点按纹理 alpha 最低点计算，不再只依赖 catalog 的 `base_pad`
- 所有可放置物统一以占地中心为底部中心
- 阴影跟随占地中心，1×1 / 2×1 / 旋转后 1×2 一致
- 桌子接入 `R` 顺时针、`Shift+R` 逆时针 90° 旋转
- 旋转预览、占格宽高、碰撞、绿红状态同步更新
- 桌子增加 1×2 朝向变体贴图，避免把原 3/4 贴图硬转 90° 后看起来像竖板
- 存档写入 `rotation`，重新加载后方向保留
- `allow_rotation` / `anchor` 已进入物件定义；当前只有桌子允许旋转

## 风格观察

- 地面用统一明亮绿色，去掉了深色逐格外框；V2 测试地形单独使用 1.35 倍重叠和同色底垫，正式场景参数未变。
- 树、石头、木桌减少细节，保留清晰外轮廓。
- 兔子保留现有设计和动画，未在本轮重新绘制；仍比新环境物件细节多，是下一轮可继续简化的重点。
- 背景水域仍使用现有矢量水面，不属于本轮的 5 种测试素材。
