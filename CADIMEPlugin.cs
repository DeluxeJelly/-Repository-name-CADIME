using System;
using System.Runtime.InteropServices;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;
using AcAp = Autodesk.AutoCAD.ApplicationServices.Application;

// 支持 GstarCAD 兼容
#if GSTAR
using GrxCAD.ApplicationServices;
using GrxCAD.DatabaseServices;
using GrxCAD.EditorInput;
using GrxCAD.Runtime;
#endif

namespace CADIMEPlugin
{
    /// <summary>
    /// CAD 智能输入法切换插件
    /// 仅在 CAD 进程内运行，不影响其他软件
    /// </summary>
    public class IMESwitcherPlugin : IExtensionApplication
    {
        #region Windows API

        [DllImport("user32.dll")]
        private static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll")]
        private static extern IntPtr GetFocus();

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        private static extern int GetClassName(IntPtr hWnd, System.Text.StringBuilder lpClassName, int nMaxCount);

        [DllImport("imm32.dll")]
        private static extern IntPtr ImmGetContext(IntPtr hWnd);

        [DllImport("imm32.dll")]
        private static extern bool ImmSetConversionStatus(IntPtr himc, int fdwConversion, int fdwSentence);

        [DllImport("imm32.dll")]
        private static extern bool ImmGetConversionStatus(IntPtr himc, out int fdwConversion, out int fdwSentence);

        [DllImport("imm32.dll")]
        private static extern bool ImmReleaseContext(IntPtr hWnd, IntPtr himc);

        // 输入法模式常量
        private const int IME_CMODE_ALPHANUMERIC = 0x0000;  // 英文模式
        private const int IME_CMODE_NATIVE = 0x0001;       // 中文模式
        private const int IME_CMODE_CHINESE = 0x0001;       // 中文

        #endregion

        private Editor _editor;
        private Document _document;

        #region 命令列表

        // 英文场景命令（输入这些时自动切英文）
        private readonly string[] _englishCommands = new[]
        {
            // 绘图
            "L", "LINE", "C", "CIRCLE", "REC", "RECTANG", "PL", "PLINE", "ARC", "POL", "POLYGON",
            "EL", "ELLIPSE", "SPL", "SPLINE", "PO", "POINT", "H", "HATCH", "GRADIENT",

            // 修改
            "CO", "COPY", "MI", "MIRROR", "AR", "ARRAY", "O", "OFFSET", "RO", "ROTATE",
            "M", "MOVE", "E", "ERASE", "EX", "EXTEND", "TR", "TRIM", "F", "FILLET",
            "CHA", "CHAMFER", "SC", "SCALE", "S", "STRETCH", "LEN", "LENGTHEN", "X", "EXPLODE",

            // 视图
            "Z", "ZOOM", "P", "PAN", "REGEN", "REDRAW",

            // 标注（命令输入）
            "DLI", "DAL", "DRA", "DDI", "DAN", "DCO", "QDIM",

            // 图层/属性
            "LA", "LAYER", "MA", "MATCHPROP", "LW", "COLOR",

            // 块
            "B", "BLOCK", "I", "INSERT", "W", "WBLOCK",

            // 测量
            "DI", "DIST", "AREA", "LIST", "ID"
        };

        // 中文场景命令（输入这些时自动切中文）
        private readonly string[] _chineseCommands = new[]
        {
            "MT", "MTEXT", "TEXT", "DT", "T", "MTEDIT",
            "TE", "TEXTEDIT", "FIELD", "TABLE", "MLEADER"
        };

        #endregion

        public void Initialize()
        {
            // 获取当前编辑器
            _editor = AcAp.DocumentManager.MdiActiveDocument.Editor;

            // 订阅命令事件
            AcAp.DocumentManager.DocumentActivated += OnDocumentActivated;
            AcAp.DocumentManager.MdiActiveDocument.CommandWillStart += OnCommandWillStart;
            AcAp.DocumentManager.MdiActiveDocument.CommandEnded += OnCommandEnded;

            // 显示加载信息
            _editor.WriteMessage("\n========================================");
            _editor.WriteMessage("\n  CAD 智能输入法切换器 v1.0 已加载");
            _editor.WriteMessage("\n========================================");
            _editor.WriteMessage("\n  输入 CADIME 开启/关闭自动切换");
            _editor.WriteMessage("\n  输入 CADIMEHELP 查看帮助");
            _editor.WriteMessage("\n========================================\n");

            // 注册命令
            CommandMethodReg.Register();
        }

        public void Terminate()
        {
            // 取消订阅
            AcAp.DocumentManager.DocumentActivated -= OnDocumentActivated;
            if (AcAp.DocumentManager.MdiActiveDocument != null)
            {
                AcAp.DocumentManager.MdiActiveDocument.CommandWillStart -= OnCommandWillStart;
                AcAp.DocumentManager.MdiActiveDocument.CommandEnded -= OnCommandEnded;
            }
        }

        #region 事件处理

        private void OnDocumentActivated(object sender, DocumentCollectionEventArgs e)
        {
            if (e.Document == null) return;

            _document = e.Document;
            _editor = _document.Editor;

            // 订阅新文档的命令事件
            _document.CommandWillStart += OnCommandWillStart;
            _document.CommandEnded += OnCommandEnded;
        }

        private void OnCommandWillStart(object sender, CommandEventArgs e)
        {
            string cmd = e.GlobalCommandName.ToUpper().Trim();

            try
            {
                // 检查是否是英文命令
                if (IsEnglishCommand(cmd))
                {
                    SwitchToEnglish();
                    _editor.WriteMessage($"\n[CADIME] 命令 '{cmd}' → 英文输入法");
                }
                // 检查是否是中文命令
                else if (IsChineseCommand(cmd))
                {
                    SwitchToChinese();
                    _editor.WriteMessage($"\n[CADIME] 命令 '{cmd}' → 中文输入法");
                }
            }
            catch (System.Exception ex)
            {
                _editor.WriteMessage($"\n[CADIME] 错误: {ex.Message}");
            }
        }

        private void OnCommandEnded(object sender, CommandEventArgs e)
        {
            // 命令结束后恢复英文（默认绘图状态）
            // SwitchToEnglish();
        }

        #endregion

        #region 命令判断

        private bool IsEnglishCommand(string cmd)
        {
            foreach (var c in _englishCommands)
            {
                if (string.Equals(c, cmd, StringComparison.OrdinalIgnoreCase))
                    return true;
            }
            return false;
        }

        private bool IsChineseCommand(string cmd)
        {
            foreach (var c in _chineseCommands)
            {
                if (string.Equals(c, cmd, StringComparison.OrdinalIgnoreCase))
                    return true;
            }
            return false;
        }

        #endregion

        #region 输入法切换

        /// <summary>
        /// 切换到英文输入模式
        /// </summary>
        public static void SwitchToEnglish()
        {
            try
            {
                IntPtr hwnd = GetFocus();
                if (hwnd == IntPtr.Zero) hwnd = GetForegroundWindow();

                IntPtr himc = ImmGetContext(hwnd);
                if (himc != IntPtr.Zero)
                {
                    // 设置为英文模式
                    ImmSetConversionStatus(himc, IME_CMODE_ALPHANUMERIC, 0);
                    ImmReleaseContext(hwnd, himc);
                }
            }
            catch { }
        }

        /// <summary>
        /// 切换到中文输入模式
        /// </summary>
        public static void SwitchToChinese()
        {
            try
            {
                IntPtr hwnd = GetFocus();
                if (hwnd == IntPtr.Zero) hwnd = GetForegroundWindow();

                IntPtr himc = ImmGetContext(hwnd);
                if (himc != IntPtr.Zero)
                {
                    // 设置为中文模式
                    ImmSetConversionStatus(himc, IME_CMODE_NATIVE | IME_CMODE_CHINESE, 0);
                    ImmReleaseContext(hwnd, himc);
                }
            }
            catch { }
        }

        /// <summary>
        /// 获取当前输入法状态
        /// </summary>
        public static bool IsChineseMode()
        {
            try
            {
                IntPtr hwnd = GetFocus();
                if (hwnd == IntPtr.Zero) return false;

                IntPtr himc = ImmGetContext(hwnd);
                if (himc == IntPtr.Zero) return false;

                ImmGetConversionStatus(himc, out int conversion, out int sentence);
                ImmReleaseContext(hwnd, himc);

                return (conversion & IME_CMODE_NATIVE) != 0;
            }
            catch
            {
                return false;
            }
        }

        #endregion
    }

    /// <summary>
    /// AutoCAD 命令注册
    /// </summary>
    public static class CommandMethodReg
    {
        [CommandMethod("CADIME")]
        public static void ToggleIME()
        {
            var doc = AcAp.DocumentManager.MdiActiveDocument;
            var ed = doc.Editor;

            // 手动切换输入法
            if (IMESwitcherPlugin.IsChineseMode())
            {
                IMESwitcherPlugin.SwitchToEnglish();
                ed.WriteMessage("\n[CADIME] 已切换到英文输入法");
            }
            else
            {
                IMESwitcherPlugin.SwitchToChinese();
                ed.WriteMessage("\n[CADIME] 已切换到中文输入法");
            }
        }

        [CommandMethod("CADIMEHELP")]
        public static void ShowHelp()
        {
            var doc = AcAp.DocumentManager.MdiActiveDocument;
            var ed = doc.Editor;

            ed.WriteMessage("\n========================================");
            ed.WriteMessage("\n  CAD 智能输入法切换器 帮助");
            ed.WriteMessage("\n========================================");
            ed.WriteMessage("\n  功能说明:");
            ed.WriteMessage("\n    - 自动识别 CAD 命令并切换输入法");
            ed.WriteMessage("\n    - LINE/COPY 等命令自动切英文");
            ed.WriteMessage("\n    - MTEXT/TEXT 等命令自动切中文");
            ed.WriteMessage("\n");
            ed.WriteMessage("\n  手动命令:");
            ed.WriteMessage("\n    CADIME      - 手动切换中英文");
            ed.WriteMessage("\n    CADIMEHELP  - 显示此帮助");
            ed.WriteMessage("\n========================================\n");
        }
    }
}
