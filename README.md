# NetNewsWire 简体中文版

基于上游 [NetNewsWire](https://github.com/Ranchero-Software/NetNewsWire) 的 macOS 自用汉化版本，不含 AI 功能。分支 `zh-hans` 长期跟随上游更新。

## 内容

- **简体中文界面**：主菜单、侧栏、工具栏、设置、添加订阅、账户登录、OPML 导入导出、日志和统计窗口、快捷键说明等。跟随 macOS 的应用语言设置。
- **三套阅读主题**：Claude（暖象牙白 / 暖炭灰，衬线正文）、宣纸（书页风格，宋体、段首缩进）、夜读（始终深色、低对比）。在「文章主题」菜单中选择。
- **自建版适配**：独立的钥匙串命名空间（避免与官方版条目冲突）；关闭上游自动更新，避免被官方版本覆盖。

## 构建与安装

需要完整的 Xcode。

**1. 创建签名证书（只需一次）**

打开「钥匙串访问」，选择菜单「钥匙串访问 → 证书助理 → 创建证书…」：名称填 `NetNewsWire Local Signing`，身份类型选「自签名根证书」，证书类型选「代码签名」。

有了固定签名，钥匙串里点过的「始终允许」在重新构建后依然有效。没有这个证书时，脚本会退回临时签名，每次重新构建后 macOS 都会再次询问钥匙串权限。

**2. 构建并安装**

```sh
bash buildscripts/build-chinese-local.sh
```

脚本会编译、签名，并直接安装到 `/Applications/NetNewsWire 汉化版.app`。构建缓存在仓库上一级的 `build/` 里；如果移动过项目目录后构建失败，删掉 `build/` 重来即可。

## 同步上游更新

```sh
git switch zh-hans
git fetch upstream
git merge upstream/main
bash buildscripts/build-chinese-local.sh
```

合并时如有冲突，多半出现在 `*.xcstrings` 翻译文件或 `project.pbxproj`：保留上游的新内容，再补回 `zh-Hans` 译文。上游新增的界面文字在补译前会显示英文。详见 [汉化与构建说明](Technotes/ChineseLocalization.md)。

## 数据与限制

- 订阅数据位于 `~/Library/Application Support/NetNewsWire/`，和官方版是同一个目录，请不要同时运行官方版和本版本。
- 阅读器视图（全文提取）等依赖上游私有服务密钥的功能不可用。
- 本地签名、未公证，只适合在本机使用。

Git 仓库保留上游完整历史和 MIT 许可证。`zh-hans` 是汉化分支，`main` 与上游保持一致。

---

以下为上游说明。

<img src=Technotes/Images/icon_1024.png height=128 width=128 style="display: block; margin: auto;"> 

# NetNewsWire

NetNewsWire is a free and open-source feed reader for macOS and iOS.

It supports [RSS](https://cyber.harvard.edu/rss/rss.html), [Atom](https://datatracker.ietf.org/doc/html/rfc4287), [JSON Feed](https://jsonfeed.org/), and [RSS-in-JSON](https://github.com/scripting/Scripting-News/blob/master/rss-in-json/README.md) formats.

More info: [https://netnewswire.com/](https://netnewswire.com/)

You can [report bugs and make feature requests](https://github.com/Ranchero-Software/NetNewsWire/issues) here on GitHub. You can also [read change notes](https://github.com/Ranchero-Software/NetNewsWire/releases/) for current and previous releases.

Here’s [How to Support NetNewsWire](Technotes/HowToSupportNetNewsWire.markdown). Spoiler: don’t send money. :)

(NetNewsWire’s Help menu has these links, so you don’t have to remember to come back to this page.)

#### Community

[Join the forum](https://discourse.netnewswire.com/) to talk with other NetNewsWire users — and to help out, if you’d like to, by testing, coding, writing, providing feedback, or just helping us think things through. Everybody is welcome and encouraged to join.

Every community member is expected to abide by the [code of conduct](CONTRIBUTING.md#code-of-conduct) which is included in the [Contributing](CONTRIBUTING.md) page.

#### Pull Requests

See the [Contributing](CONTRIBUTING.md) page for our process. They key thing is to ask before doing a PR (before even starting work). The Contributing page goes into more detail as to why it’s important to ask first.

#### Building

You can build and test NetNewsWire without a paid developer account.

```bash
git clone https://github.com/Ranchero-Software/NetNewsWire.git
```

You can locally override the Xcode settings for code signing
by creating a `DeveloperSettings.xcconfig` file locally at the appropriate path.
This allows for a pristine project with code signing set up with the appropriate
developer ID and certificates, and for developer to be able to have local settings
without needing to check in anything into source control.

You can do this in one of two ways: using the included `setup.sh` script or by creating the folder structure and file manually.

##### Using `setup.sh`

- Open Terminal and `cd` into the NetNewsWire directory. 
- Run this command to ensure you have execution rights for the script: `chmod +x setup.sh`
- Execute the script with the following command: `./setup.sh` and complete the answers.

##### Manually 

Make a directory `SharedXcodeSettings` next to where you have this repository.

The directory structure is:

```
directory/
  SharedXcodeSettings/
    DeveloperSettings.xcconfig
  NetNewsWire/
    NetNewsWire.xcodeproj
```
Example:

If your NetNewsWire Xcode project file is at:
`/Users/name/projects/NetNewsWire/NetNewsWire.xcodeproj`

Create your `DeveloperSettings.xcconfig` file at
`/Users/name/projects/SharedXcodeSettings/DeveloperSettings.xcconfig`

Then create a plain text file in it: `SharedXcodeSettings/DeveloperSettings.xcconfig` and
give it the contents:

```
CODE_SIGN_IDENTITY = Mac Developer
DEVELOPMENT_TEAM = <Your Team ID>
CODE_SIGN_STYLE = Automatic
ORGANIZATION_IDENTIFIER = <Your Domain Name Reversed>
DEVELOPER_ENTITLEMENTS = -dev
PROVISIONING_PROFILE_SPECIFIER =
```

Set `DEVELOPMENT_TEAM` to your Apple supplied development team.  You can use Keychain
Access to [find your development team ID](/Technotes/FindingYourDevelopmentTeamID.md).
Set `ORGANIZATION_IDENTIFIER` to a reversed domain name that you control or have made up.
Note that `PROVISIONING_PROFILE_SPECIFIER` should not have a value associated with it.

You can now open the `NetNewsWire.xcodeproj` in Xcode.

Now you should be able to build without code signing errors and without modifying
the NetNewsWire Xcode project.  This is a special build of NetNewsWire with some
functionality disabled.  This is because we have API keys that can't be stored in the
repository or shared between developers.  Certain account types, like iCloud and Feedly, aren't
enabled and the Reader View isn't enabled because of this.

If you have any problems, we will help you out in the forum ([see above](README.md#Community)).
