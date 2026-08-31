@echo off
chcp 65001 >nul
title FRBox SWT 文件下载
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0download-frbox-swt.ps1"
echo.
pause
