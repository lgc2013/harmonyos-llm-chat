@echo off
REM HarmonyOS 应用签名和打包脚本
REM 使用方法: 在 DevEco Studio 中配置自动签名后运行此脚本

echo ========================================
echo HarmonyOS LLM Chat 应用打包工具
echo ========================================
echo.

REM 设置 DevEco Studio 路径
set DEVECO_HOME=D:\software\Dev-eco\DevEco Studio
set HVIGOR=%DEVECO_HOME%\tools\hvigor\bin\hvigorw.bat
set HDC=%DEVECO_HOME%\sdk\default\openharmony\toolchains\hdc.exe

cd /d %~dp0

echo [1/3] 清理旧的构建文件...
if exist entry\build\default\outputs\default\*.hap del /q entry\build\default\outputs\default\*.hap

echo [2/3] 构建签名的 HAP 包...
call "%HVIGOR%" --mode module -p module=entry@default -p product=default assembleHap --no-daemon

echo [3/3] 检查构建结果...
if exist "entry\build\default\outputs\default\entry-default-signed.hap" (
    echo.
    echo ========================================
    echo 构建成功！
    echo ========================================
    echo.
    echo 签名的 HAP 包位置:
    echo   %cd%\entry\build\default\outputs\default\entry-default-signed.hap
    echo.
    echo 文件大小:
    for %%I in (entry\build\default\outputs\default\entry-default-signed.hap) do echo   %%~zI bytes
    echo.
    echo 安装方法:
    echo   1. 手机连接电脑，开启 USB 调试
    echo   2. 运行: "%HDC%" install entry\build\default\outputs\default\entry-default-signed.hap
    echo.
) else if exist "entry\build\default\outputs\default\entry-default-unsigned.hap" (
    echo.
    echo ========================================
    echo 警告：应用未签名
    echo ========================================
    echo.
    echo 未签名的 HAP 包位置:
    echo   %cd%\entry\build\default\outputs\default\entry-default-unsigned.hap
    echo.
    echo 要在真机上安装，请先在 DevEco Studio 中配置签名:
    echo   1. 打开 DevEco Studio
    echo   2. 点击 File ^> Project Structure ^> Signing Configs
    echo   3. 勾选 "Automatically generate signature"
    echo   4. 点击 "Sign In" 登录华为账号
    echo   5. 重新运行此脚本
    echo.
) else (
    echo 构建失败，请检查错误信息
)

pause
