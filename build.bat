@echo off
chcp 65001 >nul
echo ========================================
echo   CADIME 编译脚本
echo ========================================
echo.

set "PLATFORM=%~1"
if "%PLATFORM%"=="" set "PLATFORM=GstarCAD"

echo 编译平台: %PLATFORM%
echo.

if "%PLATFORM%"=="GstarCAD" (
    if not defined GSTAR_DIR (
        set "GSTAR_DIR=C:\Program Files\GstarCAD 2025"
    )
    echo 浩辰CAD目录: %GSTAR_DIR%
    dotnet build -c Release -p:CADPlatform=GstarCAD -p:GSTAR_DIR="%GSTAR_DIR%"
) else if "%PLATFORM%"=="AutoCAD" (
    if not defined ACAD_DIR (
        set "ACAD_DIR=C:\Program Files\Autodesk\AutoCAD 2026"
    )
    echo AutoCAD目录: %ACAD_DIR%
    dotnet build -c Release -p:CADPlatform=AutoCAD -p:ACAD_DIR="%ACAD_DIR%"
) else (
    echo 错误: 未知平台 %PLATFORM%
    echo 用法: build.bat [GstarCAD^|AutoCAD]
    exit /b 1
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo 编译失败!
    pause
    exit /b 1
)

echo.
echo ========================================
echo   编译成功!
echo ========================================
echo.
echo 输出文件: bin\Release\net48\CADIMEPlugin.dll
echo.
pause
