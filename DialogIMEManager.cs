using System;
using System.Runtime.InteropServices;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;

// 兼容 GstarCAD
#if GSTAR
using GrxCAD.ApplicationServices;
using GrxCAD.EditorInput;
using GrxCAD.Runtime;
#endif

namespace CADIMEPlugin
{
    /// <summary>
    /// 对话框输入法管理器
    /// 处理 MTEXT 编辑器、属性编辑器等对话框的输入法切换
    /// </summary>
    public class DialogIMEManager
    {
        #region Windows API

        [DllImport("user32.dll", SetLastError = true)]
        private static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern IntPtr FindWindowEx(IntPtr parentHandle, IntPtr childAfter, string className, string windowTitle);

        [DllImport("user32.dll")]
        private static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);

        private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        private static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);

        [DllImport("user32.dll")]
        private static extern bool IsWindowVisible(IntPtr hWnd);

        #endregion

        // 需要中文输入的对话框标题关键词
        private readonly string[] _chineseDialogKeywords = new[]
        {
            "文字", "TEXT", "MTEXT", "编辑", "EDIT", "属性", "PROPERTIES",
            "标注", "DIMENSION", "表格", "TABLE", "字段", "FIELD",
            "查找", "FIND", "替换", "REPLACE", "注释", "ANNOTATION"
        };

        // 需要英文输入的对话框
        private readonly string[] _englishDialogKeywords = new[]
        {
            "命令", "COMMAND", "坐标", "COORDINATE"
        };

        private System.Windows.Forms.Timer _monitorTimer;
        private IntPtr _lastDialog = IntPtr.Zero;

        public void StartMonitoring()
        {
            _monitorTimer = new System.Windows.Forms.Timer();
            _monitorTimer.Interval = 300;  // 300ms 检查一次
            _monitorTimer.Tick += OnTimerTick;
            _monitorTimer.Start();
        }

        public void StopMonitoring()
        {
            _monitorTimer?.Stop();
            _monitorTimer?.Dispose();
        }

        private void OnTimerTick(object sender, EventArgs e)
        {
            try
            {
                // 查找当前活动的对话框
                IntPtr activeDialog = FindActiveDialog();
                
                if (activeDialog != _lastDialog)
                {
                    _lastDialog = activeDialog;
                    
                    if (activeDialog != IntPtr.Zero)
                    {
                        // 获取对话框标题
                        string title = GetWindowTitle(activeDialog);
                        
                        // 判断需要哪种输入法
                        if (NeedsChineseInput(title))
                        {
                            IMESwitcherPlugin.SwitchToChinese();
                            Log($"对话框 '{title}' → 中文");
                        }
                        else if (NeedsEnglishInput(title))
                        {
                            IMESwitcherPlugin.SwitchToEnglish();
                            Log($"对话框 '{title}' → 英文");
                        }
                    }
                }
            }
            catch { }
        }

        private IntPtr FindActiveDialog()
        {
            // 查找当前 CAD 进程中的活动对话框
            // 简化实现：查找可见的对话框窗口
            
            IntPtr found = IntPtr.Zero;
            
            EnumWindows((hwnd, param) =>
            {
                if (!IsWindowVisible(hwnd)) return true;
                
                string title = GetWindowTitle(hwnd);
                if (string.IsNullOrEmpty(title)) return true;
                
                // 检查是否是 CAD 相关的对话框
                if (IsCADDialog(title))
                {
                    found = hwnd;
                    return false;  // 停止枚举
                }
                
                return true;
            }, IntPtr.Zero);
            
            return found;
        }

        private bool IsCADDialog(string title)
        {
            foreach (var kw in _chineseDialogKeywords)
            {
                if (title.ToUpper().Contains(kw.ToUpper()))
                    return true;
            }
            foreach (var kw in _englishDialogKeywords)
            {
                if (title.ToUpper().Contains(kw.ToUpper()))
                    return true;
            }
            return false;
        }

        private bool NeedsChineseInput(string title)
        {
            foreach (var kw in _chineseDialogKeywords)
            {
                if (title.ToUpper().Contains(kw.ToUpper()))
                    return true;
            }
            return false;
        }

        private bool NeedsEnglishInput(string title)
        {
            foreach (var kw in _englishDialogKeywords)
            {
                if (title.ToUpper().Contains(kw.ToUpper()))
                    return true;
            }
            return false;
        }

        private string GetWindowTitle(IntPtr hwnd)
        {
            System.Text.StringBuilder sb = new System.Text.StringBuilder(256);
            GetWindowText(hwnd, sb, 256);
            return sb.ToString();
        }

        private void Log(string message)
        {
            try
            {
                var doc = Application.DocumentManager.MdiActiveDocument;
                doc?.Editor.WriteMessage($"\n[CADIME] {message}");
            }
            catch { }
        }
    }
}
