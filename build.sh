#!/bin/bash
# CADIME 编译脚本 (macOS/Linux - 用于交叉编译或检查)

echo "========================================"
echo "  CADIME 编译脚本"
echo "========================================"
echo ""
echo "注意: 此项目需要在 Windows 上使用 .NET Framework 编译"
echo ""
echo "请在 Windows 上运行:"
echo "  build.bat GstarCAD    # 编译浩辰CAD版本"
echo "  build.bat AutoCAD     # 编译AutoCAD版本"
echo ""

# 检查 dotnet 是否安装
if ! command -v dotnet &> /dev/null; then
    echo "错误: 未找到 dotnet CLI"
    exit 1
fi

# 显示项目信息
echo "项目文件检查:"
dotnet sln list 2>/dev/null || echo "  (无解决方案文件)"

echo ""
echo "项目结构:"
ls -la *.csproj 2>/dev/null || echo "  (请在 Windows 上编译)"
