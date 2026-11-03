# 协作说明

## 环境

- Godot **4.7.2**（项目按此版本验证）
- 渲染器：GL Compatibility
- 主场景：`scenes/Main.tscn`
- 启动编辑器：`open_editor.bat`
- 运行测试：`run_tests.bat`

引擎不需要提交进仓库。每位协作者自行安装 Godot 4.7.2，用编辑器导入本目录的 `project.godot` 即可。

## 不要提交

以下内容已在 `.gitignore` 排除：

- `.godot/`：Godot 的导入缓存
- `.userdata/`：本机启动脚本使用的 Godot 用户缓存
- `*.tmp`、日志、系统残留文件

图片/字体的 `.import` 和 `.uid` 文件保留在仓库里，保证资源引用稳定。

## 分支建议

- `main`：可运行、可玩版本，保护分支
- `dev`：日常集成分支
- 功能开发：`feature/cooking`、`feature/ui`、`feature/characters` 等
- 修复：`fix/patience-timeout` 这种命名

小团队也建议至少走一步 Pull Request，让另一个人看一眼再合入 `main`，尤其涉及数值和场景布局时。

## 提交前

1. 用编辑器跑一遍，确认能进入营业、能完成一单。
2. 运行 `run_tests.bat`，确认窗口验收通过。
3. 不要提交本机的账号、Token、私钥、聊天记录或 `.userdata`。

## 数值修改

主要在 `data/game_config.json`：

- `cooking.states`：火候阈值与奖励
- `economy`：金币、满意度、惩罚
- `customers`：到店间隔、耐心
- `recipes` / `sauces`：订单内容

改完至少重新跑一次测试。

## 美术与资源

当前美术是程序化矢量绘制（`scripts/art/painter.gd`、`scripts/art/shop_backdrop.gd`）。
新增图片/音频时请使用统一命名，并确认授权允许分发。中文字体 Noto Sans SC 的许可文本在 `assets/fonts/OFL.txt`。
