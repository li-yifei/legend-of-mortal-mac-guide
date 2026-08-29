# 在 Apple Silicon Mac 上執行《活俠傳》：安裝、字型與 Mod 修復

[返回首頁](../README.md) · [简体中文](guide.zhs.md) · [日本語](guide.ja.md) · [한국어](guide.ko.md)

本文記錄一套在 2026 年 8 月經實機驗證可行的設定方案。適用於希望透過 Sikarugir、Wine 與 Windows 版 Steam 執行自行購買之正版《活俠傳》的 Apple Silicon Mac 使用者。

## 已驗證環境

| 項目 | 版本或測試結果 |
| --- | --- |
| 遊戲 | Steam AppID `1859910`，Build ID `20337760`，`release_1.0.5000.13` |
| Unity | `2020.3.49f1` |
| 可執行檔 | `Mortal.exe`，PE32 / x86 |
| 包裝器（Wrapper） | Sikarugir Template `1.0.11` |
| Wine | Sikarugir Wine `10.0` |
| 圖形後端 | 32 位元 DXMT，D3D11 → Metal |
| Mod 框架 | BepInEx `6.0.0-be.785` x86 Mono |

Wine、Steam、macOS 與遊戲本身的更新均可能影響相容性與執行結果。在進行任何調整時，請務必記錄版本號、保留記錄檔並建立帶有時間戳記的備份。

## 1. 建立獨立的 Windows 版 Steam 包裝器

請準備以下項目：

- Apple Silicon Mac 與 macOS 14 或更新版本；
- Rosetta 2；
- [Sikarugir 官方專案](https://github.com/Sikarugir-App/Sikarugir)；
- 個人 Steam 帳號中已擁有的 [《活俠傳》](https://store.steampowered.com/app/1859910/Legend_of_Mortal/)；
- 足夠的磁碟空間（用於存放包裝器、Steam、遊戲本體與各階段備份）。

使用 Sikarugir Creator 建立獨立包裝器（例如 `SteamWin.app`）。在包裝器專屬的 prefix 中依序完成：

1. 初始化 Wine prefix，確認已同時建立 `Program Files` 與 `Program Files (x86)` 目錄；
2. 透過 Winetricks 安裝 `cjkfonts`；
3. 套用登錄檔設定 `hidewineexports=enable`；
4. 安裝 Windows 版 Steam；
5. 將啟動目標設定為 `C:\Program Files (x86)\Steam\steam.exe`；
6. 登入 Steam 並下載安裝 AppID `1859910`。

macOS 原生 Steam 與 Windows 版 Steam 可以共存。若遇到登入或網路連線異常，請先徹底結束另一端的用戶端，避免同一帳號的工作階段相互衝突或被強制登出。

### 先確認遊戲架構

Steam 商店頁面的系統需求無法取代實際的檔案架構檢查。請執行以下指令：

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

已驗證組建（Build）的檢查結果：

```text
PE32 executable (GUI) Intel 80386, for MS Windows
```

Windows 版 Steam 常見 x86 啟動引導程式（bootstrap）。圖形後端必須依據 `Mortal.exe` 本身的 PE32（32 位元）架構進行選擇。

## 2. 修復 D3D11 圖形初始化失敗

典型症狀：Steam 短暫顯示「執行中」，隨後遊戲結束；彈出視窗或 `Player.log` 中記錄：

```text
Failed to initialize graphics.
InitializeEngineGraphics failed
d3d11: failed to create device and context (80004005)
```

針對已驗證組建（Build）測試各圖形渲染路徑的結果如下：

- Unity OpenGL：遊戲組建缺少對應的圖形裝置（graphics device）支援；
- WineD3D + MoltenVK：雖能識別 Apple GPU，但 D3D feature level 特性等級協商失敗；
- D3DMetal：主要涵蓋 64 位元 D3D11/12；
- DXMT：提供完整的 32 位元 D3D10/11 模組，適配當前 PE32 遊戲。

### 判斷 DXMT 開關是否真正生效

包裝器介面開啟 DXMT 僅代表設定已寫入。執行時仍需進一步核驗：

- `WINEDEBUG=+loaddll` 記錄檔中是否確實載入目標 `d3d11.dll`、`dxgi.dll` 與 `winemetal.dll`；
- 當前生效的 Engine DLL 其 SHA-256 雜湊值是否與目標 DXMT 版本一致；
- `Player.log` 是否回報 Direct3D 11 level 11.1 與 Apple GPU。

在這套測試環境中，初次開啟 DXMT 時遊戲實際上仍載入了 Engine 目錄中的 WineD3D。最終採用可還原的 Engine 層級修復方式：先備份原始 32 位元 WineD3D 模組，將對應版本的 DXMT `d3d10core.dll`、`d3d11.dll`、`dxgi.dll`、`winemetal.dll` 放入實際生效的 `i386-windows` 目錄，並把相符的 `winemetal.so` 放入生效的 Unix module 目錄。

不同 Engine 的目錄結構可能有所差異。請先從載入記錄檔解析出真實搜尋路徑後再行替換，且每個檔案在替換前後均應記錄 SHA-256 雜湊值。

成功載入記錄檔範例：

```text
Loaded C:\windows\system32\winemetal.dll
Loaded C:\windows\system32\DXGI.DLL
Loaded C:\windows\system32\d3d11.dll
```

Unity 初始化成功記錄檔範例：

```text
Direct3D:
    Version:  Direct3D 11.0 [level 11.1]
    Renderer: Apple <GPU>
Begin MonoManager ReloadAssembly
```

日常啟動建議使用 Steam AppID 命令列參數：

```text
steam.exe -applaunch 1859910
```

## 3. Retina 與解析度

Wine Retina 模式對應的登錄檔路徑：

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

Retina 渲染與 Unity UI 縮放是相互獨立的機制。《活俠傳》的 Unity UI 邏輯基本上忽略 Windows DPI。高解析度能提供更清晰細緻的畫面，但 UI 相對偏小；低解析度下 UI 尺寸較大，但會有明顯的放大模糊。

建議讓遊戲記住使用者自行選擇的視窗解析度。已驗證環境最終採用 `1920×1200`，並在桌面啟動捷徑中移除了強制 `-screen-width` 與 `-screen-height` 參數。

## 4. 修復商店價格與總額顯示空白

典型症狀：遊戲內的中文對話、常規數值與銅錢圖示均能正常顯示，但商店介面中的商品單價與總計金額顯示為空白。

資源檢查顯示，`MoneyValue` 與 `MoneyText` UI 元件綁定了內嵌字型 `SourceHanSerifTC-Bold`；其預設文字包含 `50`，字型圖集中也完整包含 `0–9` 數字字元。問題根源在於 Wine prefix 中的字型集合與系統字型對應映射不完整。

初始建立的 prefix 僅包含：

```text
sourcehansans.ttc
unifont.ttf
```

即使已安裝 `cjkfonts`，其涵蓋範圍依然有限。實際修復方案為透過 Winetricks 安裝：

```text
fonts → allfonts
```

操作前請徹底結束 Windows 版 Steam，並備份以下檔案：

- `drive_c/windows/Fonts`；
- `system.reg`；
- `user.reg`；
- `userdef.reg`。

安裝完成後，字型目錄從 2 個檔案增加到 121 個（約 284 MB），Arial、Tahoma、Calibri、Meiryo 與 WenQuanYi 等字型的登錄檔項目均已完整寫入。結束 wineserver 處理程序並重新啟動遊戲後，商店金額即可恢復正常顯示。

各類字型具有各自的軟體授權合約。請一律透過 Winetricks 從原始來源下載安裝，公開存放庫與預打包包裝器應保持零字型散布。

## 5. 修復 Doorstop 與 BepInEx Mod 載入

詳細實戰過程請參閱日文案例分析：[ケース：Wine 10 / x86版『活俠傳』で日本語化Modを読み込む](cases/japanese-mod.ja.md)。

### 安裝 Mod 前先做檔案層級備份

對每個壓縮檔執行以下操作：

1. 檢查壓縮檔內路徑，排除絕對路徑與 `..` 路徑遍歷（Path Traversal）安全風險；
2. 驗證 `winhttp.dll` 與外掛程式 DLL 是否為 x86（32 位元）架構；
3. 列出將被覆寫的檔案清單；
4. 將所有同名檔案複製到帶有時間戳記的備份目錄中；
5. 解壓縮合併後逐一驗證 SHA-256 雜湊值；
6. 啟動遊戲並確認記錄檔修改時間確實屬於本次執行。

Mod 安裝包可能殘留舊的 `LogOutput.log`。判斷框架狀態應結合記錄檔修改時間、當前處理程序載入的模組以及 Chainloader 輸出綜合判定。

### 第一步：載入 Doorstop

在 `winecfg → Libraries` 中為遊戲主程式新增設定：

```text
winhttp = native,builtin
```

優先使用僅作用於 `Mortal.exe` 的應用程式層級 DLL override。執行遊戲時，在處理程序中應能觀察到載入了原生 `winhttp.dll` 與 BepInEx Preloader。

### 第二步：提供匹配 Unity 版本的完整 corlibs

經比對，已驗證遊戲自帶的 `Mortal_Data/Managed/mscorlib.dll` 大小為 `3,906,048` 位元組；匹配 Unity `2020.3.49f1` 的完整未裁剪版本大小為 `4,065,792` 位元組。

將循合法途徑取得、版本精準匹配的完整 corlibs 放入：

```text
BepInEx/unstripped_corlib/
```

編輯 `doorstop_config.ini`：

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

corlibs 必須與 Unity 引擎版本完全一致，並遵守 Unity 的軟體授權合約。存放庫與 Mod 發布包保持零 corlibs 發布。

### 第三步：使用包含 Wine 修復補丁的 BepInEx 6

舊版 BepInEx 6 在 Wine 32 位元環境下可能拋出以下例外：

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

該問題由 [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201) 記錄，並在 [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254) 中修復。已驗證環境採用了包含該修復補丁的 x86 Mono 組建版本 `6.0.0-be.785`。替換前請完整備份 `BepInEx/core`。

成功載入記錄檔包含：

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

隨後應能看到各外掛程式依序載入的記錄。在已驗證環境中，DiceMaster 與日文 Mod 的 5 個外掛程式均成功由 Chainloader 正常載入。

## 6. 日常維護

- 建議關閉 Steam 全域遊戲內嵌介面（Overlay）與《活俠傳》的單一遊戲內嵌介面，降低切換應用程式視窗後的按鍵輸入鎖死機率。
- 遊玩期間建議搭配 `caffeinate` 防止系統休眠。若發生闔蓋休眠、鎖定畫面或外接顯示器熱插拔，建議徹底重新啟動遊戲、Windows 版 Steam 與 wineserver 工作階段。
- Windows 版 Steam 長時間在背景擱置後，可能不再回應 `-applaunch` 啟動指令。若 Steam `gameprocess_log.txt` 中無新增記錄，請重新啟動該 prefix 下的 Steam 與 Wine 工作階段。
- 結束遊戲與 Steam 時，請使用 Windows 版 Steam 選單中的 `Steam → Exit` 正常結束。macOS Dock 中的 Wine 圖示僅為視窗代理。

## 7. 使用隨存放庫提供的唯讀檢查指令碼

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

該指令碼僅以唯讀方式檢查包裝器設定、遊戲架構、Steam 資訊清單檔案（manifest）、登錄檔設定、字型數量、DXMT 模組雜湊值、BepInEx 記錄檔以及目前正在執行的處理程序。它絕不會主動啟動或結束 Wine、Steam 與遊戲處理程序，亦不會修改任何檔案。

## 參考資料

- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)
- [DXMT](https://github.com/3Shain/dxmt)
- [BepInEx Wine 修復補丁](https://github.com/BepInEx/BepInEx/pull/1254)
- [《活俠傳》日文 Mod](https://dlaqe2334.github.io/LOM-JPMOD/)
