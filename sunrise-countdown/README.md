# 日出日落倒计时（另一台电脑交接）

AHK v1 分层 GDI+ 桌面组件：白天倒数日落、夜里倒数日出。闲置全透明，悬停淡雾底。样式对齐 `refs/1.jfif`。字体跟酷狗歌词「霞鹜文楷 轻便版 Medium」。

本目录脚本**没有**改架构。GDI+ 全部 `DllCall` 内联，不依赖 `Gdip_All.ahk` / `Gdip.ahk`。

## 新电脑要装什么

1. **AutoHotkey v1.1 64 位**（必须是 `AutoHotkeyU64.exe`，不要 v2）
2. 字体 **霞鹜文楷 轻便版 Medium**（安装到 Windows 字体，使 GDI+ 能按这个名字找到）
3. 本目录文件

没有酷狗也可以跑：脚本会读 `%AppData%\KuGou8\KuGou.ini` 的歌词字体；读不到就回退到「霞鹜文楷 轻便版 Medium」，再不行用微软雅黑 / Segoe UI。

## 安装（计划任务，不走启动文件夹）

在资源管理器中打开本目录，双击 `install-task.bat`。

默认会：

- 把 `sunrise-countdown.ahk` 拷到 `%USERPROFILE%\Scripts\`
- 若目标目录还没有 ini，写入新电脑默认（城市北京，窗口落在工作区右上）
- 若目标目录已有 ini，**不覆盖**（保留城市和位置）
- 注册计划任务 **「日出日落倒计时」**（登录触发）
- 结束已在跑的同名脚本并用 AutoHotkeyU64 重新启动

指定 AutoHotkey 路径：

```bat
install-task.bat -AhkExe "D:\路径\AutoHotkeyU64.exe"
```

指定安装目录：

```bat
install-task.bat -InstallDir "C:\Users\你的用户名\Scripts"
```

不要把快捷方式放进「启动」文件夹。原机任务导出在 `config/日出日落倒计时.zhuanZ.xml`，里面的 UserId / AHK 路径 / 脚本路径都是旧电脑的，**不要直接导入**；用上面的 `install-task.ps1` 在新电脑重写任务。

## 改脚本时

- 保存为 **UTF-8 BOM**
- 改完必须重启 `AutoHotkeyU64`（托盘退出后再开，或再跑一次 `install-task.bat`）

## 本包文件

| 文件 | 说明 |
| --- | --- |
| `sunrise-countdown.ahk` | 主脚本（UTF-8 BOM），原样 |
| `sunrise-countdown.ini` | 新电脑默认：北京；无窗口坐标 |
| `install-task.ps1` / `.bat` | 注册计划任务并启动 |
| `config/sunrise-countdown.zhuanZ.ini` | 原机位置 `X=1560 Y=0` |
| `config/日出日落倒计时.zhuanZ.xml` | 原机 `schtasks` 导出，仅作对照 |
| `config/KuGou-LyricConfigSection.ini` | 原机酷狗歌词字体键 |
| `refs/1.jfif` | 日弧样式参考 |
| `refs/wallpaper.png` | 原机壁纸参考（脚本不读取） |

托盘 / 右键：选择城市、始终置顶、退出。时区按脚本里的 `TZ := 8`（中国）。
