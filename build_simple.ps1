# CADIME 一键编译脚本
# 保存为 build.ps1，右键"使用 PowerShell 运行"

param(
    [string]$Platform = "GstarCAD",  # 或 AutoCAD
    [string]$OutputDir = "."
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CADIME 插件编译器" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 .NET SDK
$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
if (-not $dotnet) {
    Write-Host "错误: 未找到 .NET SDK" -ForegroundColor Red
    Write-Host "请安装 .NET Framework 4.8 Developer Pack:" -ForegroundColor Yellow
    Write-Host "https://dotnet.microsoft.com/download/dotnet-framework/net48" -ForegroundColor Blue
    Read-Host "按回车退出"
    exit 1
}

# 查找 CAD 安装目录
$cadDir = $null
if ($Platform -eq "GstarCAD") {
    $possiblePaths = @(
        "C:\Program Files\GstarCAD 2025",
        "C:\Program Files (x86)\GstarCAD 2025",
        "C:\Program Files\GstarCAD 2023",
        "C:\Program Files (x86)\GstarCAD 2023"
    )
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $cadDir = $path
            break
        }
    }
} else {
    $possiblePaths = @(
        "C:\Program Files\Autodesk\AutoCAD 2026",
        "C:\Program Files\Autodesk\AutoCAD 2025",
        "C:\Program Files\Autodesk\AutoCAD 2024",
        "C:\Program Files\Autodesk\AutoCAD 2023"
    )
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $cadDir = $path
            break
        }
    }
}

if (-not $cadDir) {
    Write-Host "警告: 未找到 $Platform 安装目录" -ForegroundColor Yellow
    $cadDir = Read-Host "请手动输入 CAD 安装路径 (如 C:\Program Files\GstarCAD 2025)"
}

Write-Host "CAD 目录: $cadDir" -ForegroundColor Green
Write-Host ""

# 创建临时项目目录
$tempDir = Join-Path $env:TEMP "CADIME_Build_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host "正在创建项目文件..." -ForegroundColor Cyan

# 创建 .csproj 文件
$csproj = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net48</TargetFramework>
    <AssemblyName>CADIMEPlugin</AssemblyName>
    <RootNamespace>CADIMEPlugin</RootNamespace>
    <LangVersion>8.0</LangVersion>
    <UseWindowsForms>true</UseWindowsForms>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="System" />
    <Reference Include="System.Core" />
    <Reference Include="System.Windows.Forms" />
  </ItemGroup>
</Project>
"@
$csproj | Out-File -FilePath "$tempDir\CADIMEPlugin.csproj" -Encoding UTF8

# 创建主代码文件
$code = @"
using System;
using System.Runtime.InteropServices;
using System.Linq;

// 尝试加载 AutoCAD 引用
try {
    var acadAsm = System.Reflection.Assembly.LoadFrom(@"$cadDir\acmgd.dll");
    var acdbAsm = System.Reflection.Assembly.LoadFrom(@"$cadDir\acdbmgd.dll");
} catch {
    // 尝试 GstarCAD
    try {
        var gstarAsm = System.Reflection.Assembly.LoadFrom(@"$cadDir\GrxCAD.dll");
    } catch {
        throw new Exception("未找到 CAD 程序集");
    }
}

namespace CADIMEPlugin {
    public class IMESwitcher {
        [DllImport("imm32.dll")] static extern IntPtr ImmGetContext(IntPtr hWnd);
        [DllImport("imm32.dll")] static extern bool ImmSetConversionStatus(IntPtr himc, int fdwConversion, int fdwSentence);
        [DllImport("imm32.dll")] static extern bool ImmReleaseContext(IntPtr hWnd, IntPtr himc);
        [DllImport("user32.dll")] static extern IntPtr GetFocus();
        
        const int IME_CMODE_ALPHANUMERIC = 0x0000;
        const int IME_CMODE_NATIVE = 0x0001;
        
        static string[] EN_CMDS = { "L","LINE","C","CIRCLE","COPY","CO","MOVE","M","OFFSET","O","ZOOM","Z","PAN","P" };
        static string[] CN_CMDS = { "MT","MTEXT","TEXT","DT","T","TABLE","TB" };
        
        public static void SwitchToEnglish() {
            try {
                var hwnd = GetFocus();
                var himc = ImmGetContext(hwnd);
                if (himc != IntPtr.Zero) {
                    ImmSetConversionStatus(himc, IME_CMODE_ALPHANUMERIC, 0);
                    ImmReleaseContext(hwnd, himc);
                }
            } catch { }
        }
        
        public static void SwitchToChinese() {
            try {
                var hwnd = GetFocus();
                var himc = ImmGetContext(hwnd);
                if (himc != IntPtr.Zero) {
                    ImmSetConversionStatus(himc, IME_CMODE_NATIVE, 0);
                    ImmReleaseContext(hwnd, himc);
                }
            } catch { }
        }
        
        public static void OnCommand(string cmd) {
            cmd = cmd.ToUpper().Trim();
            if (EN_CMDS.Contains(cmd)) SwitchToEnglish();
            else if (CN_CMDS.Contains(cmd)) SwitchToChinese();
        }
    }
}
"@
$code | Out-File -FilePath "$tempDir\CADIMEPlugin.cs" -Encoding UTF8

# 编译
Write-Host "正在编译..." -ForegroundColor Cyan
Write-Host ""

try {
    & dotnet build "$tempDir\CADIMEPlugin.csproj" -c Release -o "$tempDir\bin"
    
    if ($LASTEXITCODE -eq 0) {
        $dllPath = "$tempDir\bin\CADIMEPlugin.dll"
        $outputPath = Join-Path $OutputDir "CADIMEPlugin_$Platform.dll"
        Copy-Item $dllPath $outputPath -Force
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  编译成功!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "输出文件: $outputPath" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "使用方法:" -ForegroundColor Cyan
        Write-Host "1. 在 CAD 中输入 NETLOAD" -ForegroundColor White
        Write-Host "2. 选择生成的 DLL 文件" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "编译失败!" -ForegroundColor Red
    }
} catch {
    Write-Host "错误: $_" -ForegroundColor Red
}

# 清理
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Read-Host "按回车退出"
"@

Write-Host $scriptContent
