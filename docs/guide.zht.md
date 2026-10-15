# 在 Apple Silicon Mac 上執行《活俠傳》：安裝、字型與 Mod 修復

[返回首頁](../README.md) · [简体中文](guide.zhs.md) · [日本語](guide.ja.md) · [한국어](guide.ko.md)

> 本文保留 2026-08-29、Build `20337760` 的舊版實測步驟，文中的 32 位元元件選擇對應這套設定。遊戲 1.06（Build `25953419`）的 64 位元入口修復請參閱 [1.06 升級案例](cases/game-1.06.zht.md)。新版功能的驗證範圍在該案例中分別列明。

本指南面向希望在 Apple Silicon Mac 上遊玩自購正版《活俠傳》的玩家，介紹如何藉助 Sikarugir、Wine 與 Windows 版 Steam 完成安裝，並排查圖形初始化、商店文字缺失與 Mod 無法載入等常見問題。

## 已驗證環境

| 項目 | 已驗證配置 |
| --- | --- |
| 遊戲 | Steam AppID `1859910`，Build ID `20337760`，`release_1.0.5000.13` |
| Unity | `2020.3.49f1` |
| 可執行檔 | `Mortal.exe`，PE32 / x86 |
| 包裝器（Wrapper） | Sikarugir Template `1.0.11` |
| Wine | Sikarugir Wine `10.0` |
| 圖形後端 | 32 位元 DXMT，D3D11 → Metal |
| Mod 框架 | BepInEx `6.0.0-be.785` x86 Mono |
| 最近驗證日期 | 2026-08-29 |

Wine、Steam、macOS 與遊戲本身的更新均可能影響相容性與執行結果。在進行任何配置調整時，請記錄版本號並建立帶有時間戳記的備份。

## 常見症狀速查

各修復章節僅在遇到對應症狀時按需執行。若遊戲執行正常，無需執行額外修復。

| 遇到症狀或需求 | 對應章節 | 核心操作 |
| --- | --- | --- |
| 首次安裝與配置環境 | [1. 建立獨立的 Windows 版 Steam 包裝器](#install) | 建立包裝器、安裝 Windows Steam 與遊戲 |
| 啟動閃退 / 提示 D3D11 錯誤 | [2. 修復 D3D11 圖形初始化失敗](#graphics) | 啟用 DXMT 圖形轉換（必要時手動替換 Engine DLL） |
| 畫面模糊拉伸或 UI 過小 | [3. Retina 與解析度設定](#retina) | 依需要開啟 RetinaMode，自選視窗解析度 |
| 商店介面單價與總計金額空白 | [4. 修復商店價格與總額顯示空白](#fonts) | 備份登錄檔並透過 Winetricks 安裝 allfonts 字型庫 |
| Mod 或日文補丁未生效 / 報錯 | [5. 修復 Doorstop 與 BepInEx Mod 載入](#mods) | 設定 winhttp 覆寫、補充完整 corlibs、更新 BepInEx 核心 |
| 切換視窗後鍵盤滑鼠無回應 | [6. 已知問題](#focus) | 按一下視窗頂端深色標題列恢復焦點控制 |
| 遊戲長期擱置或系統睡眠防崩 | [7. 日常維護建議](#daily) | 關閉 Overlay，使用 caffeinate，規範結束 Steam |
| 診斷當前環境配置與記錄檔 | [8. 使用隨存放庫提供的唯讀檢查指令碼](#diagnostics) | 執行唯讀檢查指令碼輸出環境報告 |

## 核心名詞簡釋

| 名詞 | 簡要說明 |
| --- | --- |
| 包裝器（Wrapper / App） | macOS 下副檔名為 `.app` 的應用程式套件，封裝了 Wine 執行環境與 Windows 程式。 |
| Wine | 讓 Windows 程式在 macOS 上使用所需系統功能的相容層。 |
| Wine prefix | 包裝器內部模擬的 Windows 系統環境（包含虛擬 C 槽檔案架構與登錄檔）。 |
| Winetricks | 用於向 Wine prefix 自動化安裝 Windows 常用執行階段元件與字型的輔助指令碼工具。 |
| DXMT | 將 Windows 的 Direct3D 11 圖形渲染指令轉譯為 Apple Metal 指令的轉換層。 |
| BepInEx | 廣泛用於 Unity 引擎遊戲的 Mod 外掛程式載入與管理框架。 |
| Doorstop / 引導鏈 | Mod 載入的入口引導工具。Doorstop 截獲啟動並調用 Preloader 準備環境，再由 Chainloader 載入具體 Mod 外掛程式。 |

<a id="install"></a>

## 1. 建立獨立的 Windows 版 Steam 包裝器

準備工作：
- Apple Silicon Mac 與 macOS 14 或更新版本；
- Rosetta 2 環境；
- [Sikarugir 官方專案](https://github.com/Sikarugir-App/Sikarugir)；
- 個人 Steam 帳號中已擁有的 [《活俠傳》](https://store.steampowered.com/app/1859910/Legend_of_Mortal/)；
- 足夠的磁碟空間（用於存放包裝器、Steam、遊戲本體與各階段備份）。

使用 Sikarugir Creator 建立獨立包裝器（例如 `SteamWin.app`）。在包裝器專屬的 Wine prefix 中依序完成以下操作：

1. 初始化 Wine prefix，確認已同時建立 `Program Files` 與 `Program Files (x86)` 目錄。
2. 透過 Winetricks 安裝 `cjkfonts`。
3. 套用登錄檔設定 `hidewineexports=enable`。
4. 安裝 Windows 版 Steam。
5. 將啟動目標設定為 `C:\Program Files (x86)\Steam\steam.exe`。
6. 登入 Steam 並下載安裝 AppID `1859910`。

macOS 原生 Steam 與 Windows 版 Steam 可以共存。若遇到登入或網路連線異常，請先徹底結束另一端的用戶端，避免同一帳號的工作階段相互衝突或被強制登出。

### 檢查遊戲主程式架構

Steam 商店頁面的系統需求無法取代實際的檔案架構檢查。請在 macOS 終端機中執行以下指令（其中 `/path/to/...` 為預留位置，請替換為遊戲在您 Mac 硬碟上的實際安裝路徑）：

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

已驗證組建（Build）的檢查結果：

```text
PE32 executable (GUI) Intel 80386, for MS Windows
```

檢查結果顯示為 PE32（32 位元 x86 架構）。在這套舊版設定中，原生入口 DLL 和圖形模組須配合 `Mortal.exe` 的 32 位元架構。託管 Mod 外掛程式可能同時支援 32 位元與 64 位元，具體取決於編譯設定、相依元件和 Unity 相容性。後續修復依遇到的症狀執行。

<a id="graphics"></a>

## 2. 修復 D3D11 圖形初始化失敗

### 故障症狀與常規啟用

典型症狀：Steam 短暫顯示「執行中」，隨後遊戲異常結束；彈出視窗或在 `Player.log` 中記錄：

```text
Failed to initialize graphics.
InitializeEngineGraphics failed
d3d11: failed to create device and context (80004005)
```

常規啟用操作：
1. 開啟包裝器設定介面。
2. 在圖形設定中開啟 DXMT 開關。
3. 啟動遊戲驗證是否能正常進入主畫面。

### 進階排查：Engine DLL 手動替換回退方案

若介面開啟 DXMT 後仍出現初始化錯誤，需透過記錄檔核驗 DXMT 是否真正生效。只有在確認系統未能載入 DXMT 模組時，才執行本 Engine 層級的回退替換方案。

替換步驟：
1. 查看 `WINEDEBUG=+loaddll` 記錄檔，確認當前生效 Engine 的真實模組目錄。
2. 備份原有的 32 位元 WineD3D 模組，並記錄原始檔案的 SHA-256 雜湊值。
3. 將對應版本的 DXMT 模組（`d3d10core.dll`、`d3d11.dll`、`dxgi.dll`、`winemetal.dll`）複製放入實際生效的 `i386-windows` 目錄。
4. 將相符的 `winemetal.so` 放入對應的 Unix 模組目錄。
5. 記錄替換後各檔案的 SHA-256 雜湊值，確保版本精確匹配。

<details markdown="1">
<summary>圖形渲染後端對比與成功載入記錄檔</summary>

在已驗證組建中測試各圖形渲染路徑的表現：
- Unity OpenGL：遊戲組建缺少對應的圖形裝置（Graphics Device）支援。
- WineD3D + MoltenVK：雖能識別 Apple GPU，但 Direct3D feature level（特性等級）協商失敗。
- D3DMetal：主要涵蓋 64 位元的 D3D11/D3D12，無法直接用於 32 位元遊戲。
- DXMT：提供完整的 32 位元 D3D10/11 模組，適配當前 32 位元（PE32）遊戲。

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

</details>

日常啟動建議使用 Steam AppID 命令列參數：

```text
steam.exe -applaunch 1859910
```

<a id="retina"></a>

## 3. Retina 與解析度設定

Wine Retina 模式對應的登錄檔路徑：

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

Retina 渲染與 Unity UI 縮放是相互獨立的機制。《活俠傳》的 Unity UI 邏輯基本上忽略 Windows DPI 設定。高解析度能提供更清晰細緻的畫面，但 UI 相對偏小；較低解析度下 UI 尺寸較大，但會有拉伸模糊現象。

建議讓遊戲記住使用者自行選擇的視窗解析度。已驗證環境採用 `1920×1200`，並在桌面捷徑的啟動參數中移除了強制的 `-screen-width` 與 `-screen-height` 參數。

<a id="fonts"></a>

## 4. 修復商店價格與總額顯示空白

### 故障症狀與修復操作

典型症狀：遊戲內的中文對話、常規數值與銅錢圖示均能正常顯示，但商店介面中的商品單價與總計金額顯示為空白。

修復操作：
1. 徹底結束 Windows 版 Steam。
2. 完整備份以下 4 處檔案與目錄：
   - `drive_c/windows/Fonts`
   - `system.reg`
   - `user.reg`
   - `userdef.reg`
3. 開啟 Winetricks，選擇並安裝：
```text
fonts → allfonts
```
4. 結束並重新啟動當前包裝器，安全重新啟動其專用的 wineserver 工作階段。
5. 啟動遊戲驗證商店金額是否正常顯示。

<details markdown="1">
<summary>字型缺失原因與測試觀察記錄</summary>

經 Unity 資源檢查確認，`MoneyValue` 與 `MoneyText` UI 元件綁定了內嵌字型 `SourceHanSerifTC-Bold`；其預設文字包含 `50`，字型圖集中也完整包含 `0–9` 數字字元。問題根源在於 Wine prefix 中的字型集合與系統字型對應映射不完整。

初始建立的 prefix 僅包含：

```text
sourcehansans.ttc
unifont.ttf
```

實測安裝 `allfonts` 後，測試環境的字型目錄由 2 個檔案增加到 121 個（約 284 MB），Arial、Tahoma、Calibri、Meiryo 與 WenQuanYi 等字型的登錄檔項目均已寫入。該檔案數量與容量為實測環境記錄，各環境的實際數量可能有所增減。

各類字型具有各自的軟體授權合約。請透過 Winetricks 從原始來源下載安裝，公開存放庫與預打包包裝器保持零字型散布。

</details>

<a id="mods"></a>

## 5. 修復 Doorstop 與 BepInEx Mod 載入

詳細排障過程請參閱案例分析：[案例：Wine 10 / x86 版《活俠傳》載入日文 Mod](cases/japanese-mod.zhs.md)。

### Mod 啟動原理與架構要求

Mod 框架的引導流程分為三個階段：
1. **Doorstop 介入**：透過偽裝的 `winhttp.dll` 在遊戲啟動時接管入口，載入 Preloader。
2. **Preloader 準備**：載入 Unity 基礎組件（corlibs）並初始化環境。
3. **Chainloader 啟動**：鏈式載入器就緒後，依序載入 `BepInEx/plugins/` 目錄下的各 Mod 外掛程式。

架構匹配規則：作為原生入口的 `winhttp.dll` 必須與歷史驗證組建版本的 32 位元（PE32）可執行檔保持一致；位於外掛程式目錄的託管 DLL（C# 編譯組件）可具備架構中立性，但須符合外掛程式自身針對 Unity 版本的相容要求。

### 安裝 Mod 前的備份與檢查流程

對每個 Mod 壓縮檔依序執行以下檢查：
1. 檢查壓縮檔內路徑，排除絕對路徑與 `..` 路徑遍歷安全風險。
2. 驗證 `winhttp.dll` 與原生 DLL 是否為 x86（32 位元）架構。
3. 列出將被覆寫的檔案清單。
4. 將所有同名檔案複製到帶有時間戳記的備份目錄中。
5. 解壓縮合併後逐一驗證 SHA-256 雜湊值。
6. 啟動遊戲並確認 `LogOutput.log` 的修改時間與本次執行完全一致（避免誤讀壓縮檔內殘留的歷史記錄檔）。

### 第一步：載入 Doorstop

在 `winecfg → Libraries` 中為遊戲主程式新增設定：

```text
winhttp = native,builtin
```

優先使用僅作用於 `Mortal.exe` 的應用程式層級 DLL override。執行遊戲時，在處理程序中應能觀察到已載入遊戲目錄下的 `winhttp.dll` 與 BepInEx Preloader。

### 第二步：提供匹配 Unity 版本的完整 corlibs

遊戲自帶的 `Mortal_Data/Managed/mscorlib.dll` 為裁剪版本（大小為 `3,906,048` 位元組）；匹配 Unity `2020.3.49f1` 的完整未裁剪版本（unstripped corlib）大小為 `4,065,792` 位元組。

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

替換前請完整備份 `BepInEx/core` 目錄。將核心檔案替換為包含 PR #1254 修復補丁的 x86 Mono 組建版本 `6.0.0-be.785`。

驗證載入成功的記錄檔特徵：

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

記錄檔中出現 `Chainloader initialized` 表明 Mod 框架初始化成功；隨後各外掛程式將輸出各自的載入資訊。在已驗證歷史配置中，DiceMaster 同樣受制於缺少 `winhttp` override、corlibs 裁剪與 BepInEx 初始化異常，透過本節相同的 Doorstop / corlibs / BepInEx Wine 修復路徑能夠成功載入執行（該結論僅適用於已驗證的歷史組建版本組合，不代表支援所有功能與後續版本）。

<details markdown="1">
<summary>BepInEx 例外詳情與修復補丁來源</summary>

舊版 BepInEx 6 在 Wine 32 位元環境下可能拋出以下例外：

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

該問題由 [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201) 記錄，並在 [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254) 中修復。

</details>

<a id="focus"></a>

## 6. 已知問題

### 切換視窗後需按一下標題列恢復控制

故障表現：在已驗證的環境中，從遊戲切換至其他 macOS 應用程式再切回《活俠傳》後，遊戲畫面正常更新，但鍵盤、滑鼠或控制器輸入可能無法在遊戲視窗內生效。

實測有效的恢復操作：
1. 切回《活俠傳》的 `Mortal` 遊戲視窗。
2. 按一下視窗頂端的 macOS 標題列（即下圖紅色箭頭所指的深色區域）一次。
3. 返回遊戲畫面繼續操作。

![按一下 Mortal 視窗標題列以恢復遊戲輸入](assets/window-titlebar-focus-recovery.png)

關閉 Steam 全域 Overlay 與《活俠傳》的個別遊戲 Overlay 可降低發生頻率。按一下標題列是目前已驗證的高信心度即時恢復方式。該問題的底層根因仍在排查中，符合 Wine、Unity 與 macOS 之間視窗焦點傳遞異常的表現特徵。

| 遊戲版本 | 觸發條件 | 結果 | 證據 | 信心度 |
| --- | --- | --- | --- | --- |
| Build `20337760` / `release_1.0.5000.13` | 從其他 macOS App 切回 Wine 遊戲視窗 | 按一下 `Mortal` 標題列後恢復遊戲控制 | 實機重現與截圖 | 高 |

<a id="daily"></a>

## 7. 日常維護建議

- 關閉 Steam 全域遊戲內嵌介面（Overlay）與《活俠傳》的單一遊戲內嵌介面，降低切換應用程式視窗後的按鍵輸入鎖死機率。
- 遊玩期間建議搭配 `caffeinate` 防止系統睡眠。若發生闔蓋睡眠、鎖定畫面或外接顯示器熱插拔，建議在儲存遊戲後徹底退出並重新啟動遊戲、Windows 版 Steam 與對應包裝器工作階段。
- 結束遊戲與 Steam 時，請先在遊戲內存檔退出，再使用 Windows 版 Steam 選單中的 `Steam → Exit` 正常結束。macOS Dock 中的 Wine 圖示僅為視窗代理。
- 重新啟動 Wine 時，先存檔並退出遊戲，再只重新啟動本遊戲包裝器的工作階段。
- Windows 版 Steam 長時間在背景擱置後，可能不再回應 `-applaunch` 啟動指令。若 Steam `gameprocess_log.txt` 中無新增記錄，請重新啟動該包裝器下的 Steam 與 Wine 工作階段。

<a id="diagnostics"></a>

## 8. 使用隨存放庫提供的唯讀檢查指令碼

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

該指令碼僅以唯讀方式檢查包裝器設定、遊戲架構、Steam 資訊清單檔案（manifest）、登錄檔設定、字型數量、DXMT 模組雜湊值、BepInEx 記錄檔以及目前正在執行的處理程序（其中 `/path/to/SteamWin.app` 為預留位置，請替換為包裝器的實際路徑）。該指令碼不會啟動或結束 Wine、Steam 與遊戲處理程序，亦不會修改任何系統或遊戲檔案。

## 參考資料

- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)
- [DXMT](https://github.com/3Shain/dxmt)
- [BepInEx Wine 修復補丁](https://github.com/BepInEx/BepInEx/pull/1254)
- [《活俠傳》日文 Mod](https://dlaqe2334.github.io/LOM-JPMOD/)
