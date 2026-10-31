# 简体中文本地开发版

本次增加简体中文界面，保留英文与西班牙文资源；跟随 macOS 的应用语言选择。

覆盖主菜单、侧栏、工具栏、设置、订阅管理、账户登录、OPML 导入导出、日志和统计窗口、文章空白提示及快捷键说明。按键绑定没有改变，文章正文和订阅名称不做机器翻译。在线帮助仍链接至上游网站。

## 构建与打开

在仓库根目录执行 `bash buildscripts/build-chinese-local.sh`。

应用安装到 `/Applications/NetNewsWire 汉化版.app`。需要完整 Xcode，首次构建需联网下载依赖。构建脚本先生成上游要求的 SecretKey.swift；没有服务密钥时使用空值，不包含私人凭据。

该版本使用独立标识 `local.edmond.NetNewsWire-Evergreen-DEBUG` 和独立数据目录，不覆盖官方版，也不自动迁移已有账户。首次启动会显示上游默认的本地示例订阅。仅用于本机开发和体验，尚未完成正式发布签名或公证。定制打包脚本禁用上游自动更新，防止定制功能被覆盖。

由于没有上游私有服务密钥，Feedly、Inoreader、全文阅读服务等相关能力可能受限；此次没有增加 Miniflux 专用接口。

## 验证

- Xcode Debug 构建通过。
- 中文资源的 printf 参数数量及类型与英文一致。
- 实际启动检查主界面、通用设置、添加订阅窗口、帮助菜单及快捷键说明；检查通用设置截图未发现文字截断。
- 原始 XIB 移入 Base.lproj 后保持内容不变；新增对应中文资源。快捷键配置文件未修改。

## 账户钥匙串修复

定制版账户凭据使用独立的 generic-password 命名空间，避免与官方版遗留的 internet-password 条目冲突（曾出现 -25299）。已存在的条目通过 SecItemUpdate 更新，不再采用先删除再添加。仅 NNWCustomBuild=true 的本地版本使用此路径，上游发行版行为保持不变。

先执行构建脚本，再运行 `bash buildscripts/check-account-keychain.sh`。检查使用一次性虚拟条目，覆盖 Reader API 密码与令牌的创建、读取、更新、删除及旧条目保留。已有失败账户可在设置中更新凭据，无需删除重建；密码需重新输入。

## 同步上游

汉化分支为 `zh-hans`，通过 merge 跟随上游。首次克隆后先添加上游远程：

```sh
git remote add upstream https://github.com/Ranchero-Software/NetNewsWire.git
```

之后每次同步：

```sh
git switch zh-hans
git fetch upstream
git merge upstream/main
```

冲突处理原则：

- `*.xcstrings`：保留上游新增或改动的条目，再补回 `zh-Hans` 译文。上游改了英文原文的条目，原译文会失效，需要重新翻译。
- `project.pbxproj`：保留上游改动，确认 `knownRegions` 中仍有 `"zh-Hans"`，三套主题（Claude、宣纸、夜读）仍在 Resources 中。
- XIB 文件：汉化时已移入 `Base.lproj/`。上游如修改了原位置的 XIB，把改动带到 `Base.lproj/` 中对应文件，并检查 `zh-Hans.lproj/*.strings` 里的对象 ID 是否仍然存在。

合并后用构建脚本编译安装，打开应用查看上游新增的界面是否有未翻译的英文。

查找缺少中文的条目：

```sh
python3 buildscripts/find-missing-zh-hans.py
```

## 发布与 App 内更新

`.github/workflows/release-zh-hans.yml` 在 GitHub 的 macOS 机器上调用 `buildscripts/package-zh-hans-release.sh`，产物为签名后的 zip 和 Sparkle 的 `appcast.xml`，一并发布到 Releases。App 的更新地址是 `releases/latest/download/appcast.xml`，因此每次发布都要标记为 latest。

- **版本号**：`CFBundleVersion` 为「上游构建号.发布序号」，如 `7226.3`；发布序号取工作流的运行次数，只增不减。显示版本沿用上游的 `MARKETING_VERSION`。
- **更新开关**：打包时写入 `NNWCustomBuild`、`NNWCustomUpdates`、`SUPublicEDKey` 和本仓库的 `SUFeedURL`。只有 `NNWCustomUpdates` 为真时汉化版才启用 Sparkle，本地构建仍不更新。
- **代码签名**：自签名证书「NetNewsWire zh-Hans Signing」，有效期至 2046 年。证书固定，更新后钥匙串里的「始终允许」不失效。备份在登录钥匙串中。
- **更新签名**：Sparkle EdDSA 密钥，公钥写在打包脚本里，私钥存于仓库 Secrets，备份在登录钥匙串（账户 `netnewswire-zh-hans`）。私钥丢失后已安装的 App 无法再接收更新，只能手动重装。
- **编译配置**：沿用 Debug 配置的本地标识和免 App Group 授权设置，同时开启编译优化。
