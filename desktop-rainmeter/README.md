# 桌面组件（Rainmeter）

把本机桌面上框出来的四块同步进仓库，方便其他电脑同样显示：

- 右上角「专业团队」照片
- 右下角钢铁侠时钟（17:31 / MONDAY / 日期）
- 左下角 illustro 系统信息（CPU / RAM / SWAP）和双硬盘
- 左下角周期表

不含桌面图标、工程文件夹、快捷方式。那些路径每台电脑不同，不能靠仓库还原。

Windows 自带的 Segoe 字体没有放进仓库（每台电脑都有）。时钟用的 Facon / HelveticaNeue / ITC Avant Garde 已包含。

## 其他电脑怎么用

1. 安装 [Rainmeter](https://www.rainmeter.net/)
2. 先 `git clone`（或 `git pull`）本仓库
3. 进入 `desktop-rainmeter`，双击 `install-desktop.bat`

会把皮肤拷到当前 Rainmeter 的 SkinPath，并加载布局 `DesktopWidgets`。分辨率不同时，组件可能要自己拖一下位置。

## 本机改完怎么上传

改 Rainmeter 皮肤或位置后，在 Cursor 里打开本仓库，说「上传桌面组件」。
