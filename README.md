# NetNewsWire 简体中文版

基于上游 [NetNewsWire](https://github.com/Ranchero-Software/NetNewsWire) 的 macOS 简体中文自用版，`zh-hans` 分支长期跟随上游更新。

## 特性

- **简体中文界面**：完整汉化菜单、侧栏、设置、账户登录、日志与快捷键说明等（跟随系统语言）。
- **三套阅读主题**：新增 **Claude**、**宣纸**、**夜读**，可在「文章主题」菜单中选择。
- **独立更新与凭据**：使用独立钥匙串命名空间与 Sparkle 更新源，不与官方版冲突。

## 下载与安装

仅支持 **Apple 芯片** Mac，需 **macOS 15** 或更高版本（使用自签名证书，未经 Apple 公证）。

1. 前往 [Releases](https://github.com/edmondxie779/netnewswire-chinese/releases/latest) 下载 `NetNewsWire-zh-Hans-….zip`，解压后将「NetNewsWire 汉化版」拖入「应用程序」。
2. 首次打开若提示无法验证开发者，前往「系统设置 → 隐私与安全性」点击「仍要打开」即可。
3. 后续可通过菜单「NetNewsWire → 检查更新…」自动升级。

## 注意事项

- 订阅数据与官方版共用 `~/Library/Application Support/NetNewsWire/`，**请勿同时运行官方版与本版本**。
- 因不含上游私有服务密钥，阅读器视图（全文提取）等功能不可用。

## 维护与构建

详细说明见 [汉化与构建说明](Technotes/ChineseLocalization.md)。

- **同步上游**：`git fetch upstream && git merge upstream/main && python3 buildscripts/find-missing-zh-hans.py`
- **发布版本**：`gh workflow run release-zh-hans.yml -R edmondxie779/netnewswire-chinese`
- **本地构建**：`bash buildscripts/build-chinese-local.sh`（需完整 Xcode）

本仓库保留上游完整历史与 MIT 许可证；`zh-hans` 为汉化分支，`main` 与上游一致。
