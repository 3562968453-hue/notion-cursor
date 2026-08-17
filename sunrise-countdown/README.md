# 日出日落倒计时

AHK v1 分层 GDI+ 桌面组件：白天倒数日落、夜里倒数日出。闲置全透明，悬停淡雾底。样式对齐 `refs/1.jfif`。字体跟酷狗歌词「霞鹜文楷 轻便版 Medium」。

GDI+ 全部 `DllCall` 内联，不依赖 `Gdip_All.ahk`。主脚本不要换架构。

## 多台电脑怎么跟云端 Agent 同步

云端 Agent **读不到、也写不进** 各台电脑的 `C:\`。能互通的只有 **GitHub 仓库**。

```
手机 / 任意电脑  →  跟绑定本仓库的云端 Agent 说话
                      ↓
                 Agent 改仓库、提交、PR、合并到 main
                      ↓
        各台 Windows 的 git clone 定时 git pull
                      ↓
              重启 AutoHotkeyU64（ini 不动）
```

因此正确用法是：

1. **每台电脑都 `git clone` 同一仓库**，组件从 clone 里的 `sunrise-countdown.ahk` 运行（不要再拷一份到别的 Scripts 目录，否则会漂）。
2. 跟 Agent 说话时用 **这个 GitHub 仓库的云端对话**，不要丢 `C:\Users\...` 路径让云端去读。本机改过的文件：在那台电脑 `git push`，或像这次一样把 zip 传到对话。
3. 合并到 `main` 之后，各台会在登录时、以及默认每 20 分钟 `git pull`。立刻要的话，双击 `update.bat`。
4. **不同步的本机状态**：窗口坐标、城市写在 `sunrise-countdown.ini`（已 gitignore）。酷狗路径、AHK 安装路径各机不同，也留在本机。

## 每台电脑做一次

1. 安装 Git，并对这个仓库有权限（GitHub 登录 / Credential Manager）
2. clone 后进入本目录，先双击 `install-deps.bat`（装 AutoHotkey v1.1.37.02 64 位便携版 + 字体「霞鹜文楷 轻便版 Medium」）
3. 再双击 `install-task.bat`（注册计划任务；若还没装依赖，它会先跑 `install-deps`）

```bat
cd /d %USERPROFILE%\src\notion-cursor\sunrise-countdown
install-task.bat
```

找不到 AHK 时：

```bat
install-task.bat -AhkExe "D:\路径\AutoHotkeyU64.exe"
```

不要用启动文件夹。计划任务名仍是 **「日出日落倒计时」**。原机 XML 在 `config/日出日落倒计时.zhuanZ.xml`，路径已绑死旧电脑，不要直接导入。

关掉定时拉取：`install-task.bat -SyncMinutes 0`

## 改脚本时

- 保存为 **UTF-8 BOM**
- 改完重启 `AutoHotkeyU64`（或再跑 `update.bat` / `install-task.bat`）

## 文件

| 文件 | 说明 |
| --- | --- |
| `sunrise-countdown.ahk` | 主脚本（UTF-8 BOM），原样 |
| `sunrise-countdown.ini.example` | 新电脑默认（北京、无窗口坐标） |
| `sunrise-countdown.ini` | 本机生成，不同步 |
| `install-deps.ps1` / `.bat` | 下载并安装 AHK v1.1.37.02 U64 + 霞鹜文楷轻便版 Medium |
| `install-task.ps1` / `.bat` | 注册计划任务（登录 + 定时 pull） |
| `update.ps1` / `.bat` | 立刻 git pull 并按需重启 |
| `runtime/` | 本机下载的 AHK / 字体缓存，不同步 |
| `config/sunrise-countdown.zhuanZ.ini` | 原机位置 `X=1560 Y=0` |
| `config/日出日落倒计时.zhuanZ.xml` | 原机任务导出，仅对照 |
| `config/KuGou-LyricConfigSection.ini` | 原机酷狗歌词字体键 |
| `refs/1.jfif` | 日弧样式参考 |
| `refs/wallpaper.png` | 原机壁纸参考（脚本不读取） |

托盘 / 右键：选择城市、始终置顶、退出。时区 `TZ := 8`。
