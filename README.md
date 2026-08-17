# notion-cursor

个人方案仓库。日出日落倒计时在 `sunrise-countdown/`。

仓库：https://github.com/3562968453-hue/notion-cursor

## 其他电脑怎么下载来用

### 方法一：Git 克隆（推荐，以后能自动更新）

1. 安装 [Git for Windows](https://git-scm.com/download/win)
2. 用 GitHub 账号登录一次（第一次 `git clone` 或 `git push` 时会弹窗）
3. 打开命令提示符，执行：

```bat
mkdir %USERPROFILE%\src
cd /d %USERPROFILE%\src
git clone https://github.com/3562968453-hue/notion-cursor.git
cd notion-cursor\sunrise-countdown
install-deps.bat
install-task.bat
```

装好后：登录 Windows 会自动启动；托盘里能看到「日出日落倒计时」。闲置全透明，鼠标悬停才有淡雾底。

立刻同步云端改动：再进这个文件夹，双击 `update.bat`。

### 方法二：只下压缩包（不装 Git）

1. 打开 https://github.com/3562968453-hue/notion-cursor
2. 点绿色 **Code** → **Download ZIP**
3. 解压后进入里面的 `sunrise-countdown` 文件夹
4. 双击 `install-deps.bat`，再双击 `install-task.bat`

这种方式不会自动更新，下次改方案要重新下载。

## 本机改完怎么上传

在 Cursor 里打开 `C:\Users\anrui.wei\src\notion-cursor`，对 Agent 说「上传 xxx」。  
不要提交 `sunrise-countdown.ini`、`runtime/`、`update.log`（本机位置、城市、AHK 安装文件，各电脑不同）。  
`fonts/Facon.ttf` 会随仓库一起同步，其他电脑 clone 后外观一致。
