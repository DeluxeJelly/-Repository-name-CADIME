# CAD 智能输入法切换插件

**CADIME** - CAD Intelligent IME Switcher

专为 CAD 设计的输入法自动切换插件，仅在 CAD 进程内运行，不影响其他软件。

## 特点

- ✅ **纯 CAD 插件** - 仅在 CAD 进程内运行，不影响其他软件
- ✅ **命令级识别** - 根据当前输入的命令自动切换输入法
- ✅ **对话框感知** - 自动识别 MTEXT 编辑器、属性面板等对话框
- ✅ **双平台支持** - 支持浩辰CAD 和 AutoCAD
- ✅ **零配置** - 加载即用，无需额外设置

## 支持的 CAD 软件

| 软件 | 版本 | 状态 |
|------|------|------|
| 浩辰CAD | 2023/2025 | ✅ 已测试 |
| AutoCAD | 2020-2026 | ✅ 已测试 |
| 中望CAD | 2020+ | ⚠️ 待验证 |

## 安装方法

### 方法1：直接加载 DLL

1. 编译项目生成 `CADIMEPlugin.dll`
2. 在 CAD 命令行输入：
   ```
   NETLOAD
   ```
3. 选择 `CADIMEPlugin.dll` 文件
4. 插件自动加载并开始工作

### 方法2：添加到启动组（推荐）

**浩辰CAD：**
1. 将 `CADIMEPlugin.dll` 复制到：
   ```
   C:\Users\<用户名>\AppData\Roaming\GstarCAD\2025\zh-CN\Support\
   ```
2. 编辑 `acad.lsp` 或 `gcad.lsp`，添加：
   ```lisp
   (command "_.NETLOAD" "CADIMEPlugin.dll")
   ```

**AutoCAD：**
1. 将 `CADIMEPlugin.dll` 复制到：
   ```
   C:\Users\<用户名>\AppData\Roaming\Autodesk\AutoCAD 2026\R25.1\chs\Support\
   ```
2. 编辑 `acad.lsp`，添加：
   ```lisp
   (command "_.NETLOAD" "CADIMEPlugin.dll")
   ```

## 使用方法

### 自动模式

插件加载后自动工作：
- 输入 `LINE`, `COPY` 等命令 → 自动切换英文
- 输入 `MTEXT`, `TEXT` 等命令 → 自动切换中文
- 打开文字编辑器 → 自动切换中文

### 手动命令

| 命令 | 功能 |
|------|------|
| `CADIME` | 手动切换中英文输入法 |
| `CADIMEHELP` | 显示帮助信息 |

## 编译方法

### 编译浩辰CAD版本

```bash
dotnet build -c Release -p:CADPlatform=GstarCAD -p:GSTAR_DIR="C:\Program Files\GstarCAD 2025"
```

### 编译AutoCAD版本

```bash
dotnet build -c Release -p:CADPlatform=AutoCAD -p:ACAD_DIR="C:\Program Files\Autodesk\AutoCAD 2026"
```

## 技术原理

```
┌─────────────────────────────────────────┐
│  CAD 进程                               │
│  ┌─────────────────────────────────────┐│
│  │  CADIME 插件                        ││
│  │  ┌─────────────┐  ┌──────────────┐ ││
│  │  │ 命令拦截器   │  │ 对话框监听器  │ ││
│  │  │             │  │              │ ││
│  │  │ LINE → 英文 │  │ MTEXT → 中文 │ ││
│  │  │ COPY → 英文 │  │ 属性 → 中文  │ ││
│  │  │ MTEXT→ 中文 │  │              │ ││
│  │  └──────┬──────┘  └──────┬───────┘ ││
│  │         │                │         ││
│  │         └───────┬────────┘         ││
│  │                 ▼                  ││
│  │         ┌──────────────┐           ││
│  │         │ Windows API  │           ││
│  │         │ ImmSetConv...│           ││
│  │         └──────────────┘           ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

## 命令映射表

### 自动切换英文的命令

```
绘图: L, LINE, C, CIRCLE, REC, RECTANG, PL, PLINE, ARC, POL, POLYGON...
修改: CO, COPY, MI, MIRROR, AR, ARRAY, O, OFFSET, RO, ROTATE...
视图: Z, ZOOM, P, PAN, REGEN...
标注: DLI, DAL, DRA, DDI, DAN, DCO, QDIM...
图层: LA, LAYER, MA, MATCHPROP...
```

### 自动切换中文的命令

```
文字: MT, MTEXT, TEXT, DT, T, MTEDIT, TE...
表格: TABLE, TB...
引线: MLEADER, MLD...
```

## 常见问题

### Q: 插件加载后没有反应？

A: 检查以下几点：
1. 确认 DLL 版本与 CAD 版本匹配（32/64位）
2. 检查 CAD 命令行是否有错误信息
3. 尝试手动输入 `CADIME` 命令测试

### Q: 如何临时禁用？

A: 在 CAD 命令行输入：
```
UNLOADMODULES CADIMEPlugin
```

### Q: 支持自定义命令吗？

A: 可以修改源代码中的 `_englishCommands` 和 `_chineseCommands` 数组，重新编译即可。

## 许可证

MIT License
