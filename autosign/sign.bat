@echo off
chcp 65001 >nul
echo ========================================
echo HarmonyOS LLM Chat 应用签名工具
echo ========================================
echo.
echo 正在配置自动签名...
echo.

cd /d %~dp0

REM 设置签名工具路径
set SIGN_TOOL=D:\software\Dev-eco\DevEco Studio\sdk\default\openharmony\toolchains\lib\hap-sign-tool.jar

REM 1. 生成 CA 证书
echo [1/4] 生成 CA 证书...
java -jar "%SIGN_TOOL%" generate-ca -keyAlias "root-ca-key" -keyPwd "123456" -keyAlg ECC -keySize NIST-P-256 -issuer "C=CN,O=LLMChat,OU=Dev,CN=Root CA" -subject "C=CN,O=LLMChat,OU=Dev,CN=Root CA" -validity 3650 -keystoreFile "llmchat.p12" -keystorePwd "123456" -signAlg SHA256withECDSA -outFile "root-ca.cer"
if %ERRORLEVEL% neq 0 (
    echo 生成 CA 证书失败
    pause
    exit /b 1
)

REM 2. 生成应用证书
echo [2/4] 生成应用证书...
java -jar "%SIGN_TOOL%" generate-app-cert -keyAlias "app-key" -signAlg SHA256withECDSA -issuer "C=CN,O=LLMChat,OU=Dev,CN=Root CA" -issuerKeyAlias "root-ca-key" -subject "C=CN,O=LLMChat,OU=Dev,CN=LLMChat App" -keystoreFile "llmchat.p12" -keystorePwd "123456" -keyPwd "123456" -outFile "app.cer" -validity 365 -rootCaCertFile "root-ca.cer" -subCaCertFile "sub-ca.cer"
if %ERRORLEVEL% neq 0 (
    echo 生成应用证书失败
    echo 注意：HarmonyOS NEXT 需要华为开发者平台的 Profile 文件
    echo.
    echo 请按以下步骤操作：
    echo 1. 打开 DevEco Studio
    echo 2. 点击 File ^> Project Structure ^> Signing Configs
    echo 3. 勾选 "Automatically generate signature"
    echo 4. 登录华为账号后点击 OK
    echo 5. 重新运行此脚本
    pause
    exit /b 1
)

echo.
echo ========================================
echo 签名配置完成！
echo ========================================
echo.
echo 证书文件已生成在: %cd%
echo.
pause
