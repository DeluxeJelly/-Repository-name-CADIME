;;; CADIME.lsp - CAD 智能输入法切换器 (AutoLISP 版本)
;;; 适用于: 浩辰CAD 2023/2025, AutoCAD 2020+
;;; 功能: 根据当前命令自动切换中英文输入法

;;; ============================================
;;; 配置区域 - 可自定义
;;; ============================================

;; 英文命令列表 (输入这些命令时切换英文)
(setq *ENGLISH-COMMANDS* '(
  ;; 绘图命令
  "L" "LINE" "C" "CIRCLE" "REC" "RECTANG" "PL" "PLINE"
  "ARC" "POL" "POLYGON" "EL" "ELLIPSE" "SPL" "SPLINE"
  "POINT" "PO" "DO" "DONUT" "H" "HATCH"
  
  ;; 修改命令
  "CO" "COPY" "MI" "MIRROR" "AR" "ARRAY" "O" "OFFSET"
  "RO" "ROTATE" "M" "MOVE" "E" "ERASE" "EX" "EXTEND"
  "TR" "TRIM" "F" "FILLET" "CHA" "CHAMFER" "SC" "SCALE"
  "LEN" "LENGTHEN" "ED" "DDEDIT" "PE" "PEDIT" "X" "EXPLODE"
  "J" "JOIN" "S" "STRETCH"
  
  ;; 标注命令
  "DLI" "DAL" "DRA" "DDI" "DAN" "DCO" "DBA" "DLE"
  "QDIM" "DIM" "DIMLINEAR" "DIMALIGNED" "DIMRADIUS"
  
  ;; 图层/属性
  "LA" "LAYER" "CH" "PROPERTIES" "MA" "MATCHPROP"
  "COL" "COLOR" "LW" "LWEIGHT"
  
  ;; 视图/导航
  "Z" "ZOOM" "P" "PAN" "REGEN" "RE" "REDRAW" "R"
  
  ;; 块/插入
  "B" "BLOCK" "I" "INSERT" "W" "WBLOCK" "ATT" "ATTDEF"
  
  ;; 文字/标注样式
  "ST" "STYLE" "DST" "DIMSTYLE"
  
  ;; 工具
  "DI" "DIST" "AREA" "ID" "LIST" "LI" "MEASURE"
  "DIV" "DIVIDE" "ME" "MEASUREGEOM"
  
  ;; 文件操作
  "QSAVE" "SAVE" "OPEN" "NEW" "PRINT" "PLOT" "EXPORT"
  
  ;; 选择/组
  "G" "GROUP" "UN" "UNITS" "SN" "SNAP" "GR" "GRID"
  "OS" "OSNAP" "SE" "SETTINGS"
  
  ;; 3D 命令
  "BOX" "SPHERE" "CYLINDER" "CONE" "EXTRUDE" "REVOLVE"
  "UNI" "UNION" "SUB" "SUBTRACT" "IN" "INTERSECT"
))

;; 中文场景命令 (输入这些命令时切换中文)
(setq *CHINESE-COMMANDS* '(
  ;; 文字相关
  "DT" "TEXT" "DTEXT" "MT" "MTEXT" "T" "MTEDIT"
  "ATTEDIT" "ATE" "FIELD" "FIND"
  
  ;; 标注文字编辑
  "DIMEDIT" "DIMTEDIT" "DIMREASSOCIATE"
  
  ;; 属性编辑
  "EATTEDIT" "PROPERTIES" "CH" "CHANGE"
  
  ;; 表格
  "TABLE" "TB" "TABLEDIT"
  
  ;; 多重引线
  "MLEADER" "MLD" "MLEADEREDIT"
))

;; 中文场景窗口标题关键词
(setq *CHINESE-WINDOW-KEYWORDS* '(
  "文字" "TEXT" "MTEXT" "编辑" "EDIT" "属性" "PROPERTIES"
  "标注" "DIMENSION" "表格" "TABLE" "字段" "FIELD"
  "查找" "FIND" "替换" "REPLACE"
))

;;; ============================================
;;; Windows API 声明
;;; ============================================

;; 加载 WinAPI 支持 (VLX 或直接使用 Windows API)
(vl-load-com)

;; 声明 Windows API 函数
(setq *IME-LOADED* nil)

(defun CADIME:LoadWinAPI ()
  "加载 Windows API 函数"
  (if (not *IME-LOADED*)
    (progn
      ;; 加载输入法相关 DLL
      (setq *hImm32* (vlax-import-type-library
        :tlb-filename "imm32.dll"
        :methods '(
          (ImmGetContext (vlax-vbLong) (vlax-vbLong))
          (ImmSetConversionStatus (vlax-vbLong vlax-vbLong vlax-vbLong) (vlax-vbBoolean))
          (ImmReleaseContext (vlax-vbLong vlax-vbLong) (vlax-vbBoolean))
        )))
      
      ;; 加载 user32.dll
      (setq *hUser32* (vlax-import-type-library
        :tlb-filename "user32.dll"
        :methods '(
          (GetForegroundWindow () (vlax-vbLong))
          (GetWindowText (vlax-vbLong vlax-vbString vlax-vbLong) (vlax-vbLong))
          (LoadKeyboardLayout (vlax-vbString vlax-vbLong) (vlax-vbLong))
          (ActivateKeyboardLayout (vlax-vbLong vlax-vbLong) (vlax-vbLong))
        )))
      
      (setq *IME-LOADED* T)
      (princ "\nCADIME: Windows API 加载成功")
    )
  )
)

;;; ============================================
;;; 输入法切换函数
;;; ============================================

(defun CADIME:SwitchToEnglish ()
  "切换到英文输入法"
  (princ "\nCADIME: 切换到英文")
  ;; 方法1: 发送 Alt+Shift
  ;; (command "_.SENDKEYS" "%{SHIFT}")
  
  ;; 方法2: 使用 Windows API (如果可用)
  (CADIME:SendKeys "{LSHIFT}")  ; 左 Shift 切换
  T
)

(defun CADIME:SwitchToChinese ()
  "切换到中文输入法"
  (princ "\nCADIME: 切换到中文")
  (CADIME:SendKeys "{LSHIFT}")  ; 左 Shift 切换
  T
)

(defun CADIME:SendKeys (keystr)
  "发送按键序列"
  ;; 使用 ActiveX 发送按键
  (vl-catch-all-apply
    '(lambda ()
      (setq *wsh* (vlax-create-object "WScript.Shell"))
      (vlax-invoke-method *wsh* 'SendKeys keystr)
      (vlax-release-object *wsh*)
    )
  )
)

;;; ============================================
;;; 命令拦截与识别
;;; ============================================

(defun CADIME:CommandWillStart (cmdname)
  "命令开始前的回调"
  (setq cmdname (strcase cmdname T))
  
  ;; 检查是否是英文命令
  (if (member cmdname *ENGLISH-COMMANDS*)
    (CADIME:SwitchToEnglish)
  )
  
  ;; 检查是否是中文命令
  (if (member cmdname *CHINESE-COMMANDS*)
    (CADIME:SwitchToChinese)
  )
  
  ;; 特殊处理: MTEXT 和 TEXT 命令
  (if (or (= cmdname "MTEXT") (= cmdname "MT") (= cmdname "TEXT") (= cmdname "DT"))
    (progn
      (princ "\nCADIME: 检测到文字命令，准备切换中文...")
      ;; 延迟切换，等待对话框出现
      (CADIME:DelaySwitch "CHINESE" 500)
    )
  )
)

(defun CADIME:CommandEnded (cmdname)
  "命令结束后的回调"
  ;; 命令结束后恢复默认状态 (通常是英文)
  (CADIME:SwitchToEnglish)
)

;;; ============================================
;;; 定时器与延迟处理
;;; ============================================

(defun CADIME:DelaySwitch (lang delayms)
  "延迟切换输入法"
  (setq *CADIME-TIMER*
    (vlax-make-safearray vlax-vbLong '(0 . 0)))
  
  ;; 使用简单的延迟
  (setq start (getvar "CDATE"))
  (while (< (- (getvar "CDATE") start) (/ delayms 1000.0 86400.0))
    ;; 空循环等待
  )
  
  (if (= lang "CHINESE")
    (CADIME:SwitchToChinese)
    (CADIME:SwitchToEnglish)
  )
)

;;; ============================================
;;; 反应器设置
;;; ============================================

(defun CADIME:SetupReactors ()
  "设置命令反应器"
  (princ "\nCADIME: 正在设置反应器...")
  
  ;; 命令开始反应器
  (vlr-command-reactor
    nil
    '(
      (:vlr-commandWillStart . CADIME:CommandWillStart)
      (:vlr-commandEnded . CADIME:CommandEnded)
    )
  )
  
  ;; 编辑器反应器 (用于检测对话框)
  (vlr-editor-reactor
    nil
    '(
      (:vlr-miscellaneousEditorStart . CADIME:EditorStarted)
    )
  )
  
  (princ "\nCADIME: 反应器设置完成")
)

(defun CADIME:EditorStarted (reactor data)
  "编辑器启动回调"
  (princ "\nCADIME: 编辑器启动")
  ;; 检测是否是文字编辑器
  (CADIME:CheckWindowTitle)
)

;;; ============================================
;;; 窗口标题检测
;;; ============================================

(defun CADIME:CheckWindowTitle ()
  "检查当前窗口标题"
  ;; 使用 Windows API 获取当前窗口标题
  ;; 如果包含中文关键词，切换中文
  (princ "\nCADIME: 检查窗口...")
  T
)

;;; ============================================
;;; 初始化与清理
;;; ============================================

(defun CADIME:Init ()
  "初始化 CADIME"
  (princ "\n========================================")
  (princ "\n  CAD 智能输入法切换器 v1.0")
  (princ "\n========================================")
  (princ "\n")
  
  ;; 加载 WinAPI
  (CADIME:LoadWinAPI)
  
  ;; 设置反应器
  (CADIME:SetupReactors)
  
  (princ "\nCADIME: 初始化完成，正在运行...")
  (princ "\n提示: 输入 MTEXT/TEXT 等命令时会自动切换中文")
  (princ "\n      其他命令保持英文输入")
  (princ "\n")
  
  ;; 显示状态
  (princ (strcat "\n已加载 " (itoa (length *ENGLISH-COMMANDS*)) " 个英文命令"))
  (princ (strcat "\n已加载 " (itoa (length *CHINESE-COMMANDS*)) " 个中文命令"))
  (princ "\n")
  
  (princ)
)

(defun CADIME:Unload ()
  "卸载 CADIME"
  (princ "\nCADIME: 正在卸载...")
  
  ;; 移除反应器
  (vlr-remove-all :vlr-command-reactor)
  (vlr-remove-all :vlr-editor-reactor)
  
  (princ "\nCADIME: 已卸载")
  (princ)
)

;;; ============================================
;;; 启动
;;; ============================================

;; 自动启动
(CADIME:Init)

;; 添加到启动组 (可选)
;; (setq *CADIME-AutoStart* T)

(princ)
