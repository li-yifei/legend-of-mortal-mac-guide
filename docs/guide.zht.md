---
layout: page
title: "在 Apple Silicon Mac 上執行《活俠傳》：安裝、字型與 Mod 修復"
permalink: /docs/guide.zht/
---

[返回首頁](../README.md) · [简体中文](guide.zhs.md) · [日本語](guide.ja.md) · [한국어](guide.ko.md)

> **本文對應遊戲 1.06（Build `25953419`，64 位元）。** 2026 年 10 月 15 日在本機驗證。
> - 從 1.05 升級上來、Mod 突然全部失效：直接看 [從 1.05 升級到 1.06](#upgrade)。
> - 還在用 1.05（Build `20337760`，32 位元）：看文末的 [1.05 歷史設定](#legacy)。
{: .callout}

本指南適用於在 Apple Silicon Mac 上遊玩自購正版《活俠傳》的玩家：用 Sikarugir、Wine 與 Windows 版 Steam 安裝遊戲，並處理圖形初始化、商店文字缺失、Mod 無法載入等常見問題。

* 目錄
{:toc}

## 已驗證環境

| 項目 | 已驗證設定 |
| --- | --- |
| 遊戲 | Steam AppID `1859910`，Build `25953419`，1.06 |
| Unity | `2020.3.49f1` |
| 遊戲程式 | `Mortal.exe`、`UnityPlayer.dll`，PE32+ / x64 |
| 包裝器執行元件 | Sikarugir Creator `1.0.2`、Template `1.0.22` |
| Wine | Sikarugir Wine `10.0 revision 8` |
| 圖形後端 | 範本搭配的 DXMT `v0.80-244-g7c8dee1`，D3D11 → Metal |
| Mod 入口 | Doorstop `4.4.0` Windows x64（`winhttp.dll`） |
| Mod 框架 | BepInEx `6.0.0-be.785` Unity.Mono 託管核心 |
| 驗證日期 | 2026-10-15 |

這套環境是在 1.05 時期建好的 Wine prefix 上升級而來，字型、登錄檔與 DLL override 都沿用當時的設定。Wine、Steam、macOS 與遊戲本身的更新都可能影響結果；調整任何設定前，請記錄版本號並做帶時間戳記的備份。

## 常見症狀速查

只在遇到對應症狀時執行對應章節。遊戲執行正常就不需要額外修復。

| 症狀或需求 | 對應章節 |
| --- | --- |
| 首次安裝 | [1. 建立 Windows 版 Steam 包裝器](#install) |
| 更新到 1.06 後 Mod 同時失效 | [從 1.05 升級到 1.06](#upgrade) |
| 啟動閃退 / D3D11 錯誤 | [2. 修復 D3D11 圖形初始化失敗](#graphics) |
| 畫面模糊或 UI 過小 | [3. Retina 與解析度](#retina) |
| 商店單價與總額空白 | [4. 修復商店價格顯示空白](#fonts) |
| Mod 未生效 / 報錯 | [5. 安裝與修復 BepInEx Mod](#mods) |
| 想裝日文 Mod | [6. 日文 Mod v2.5](#jpmod) |
| 切換視窗後鍵盤滑鼠無回應 | [7. 已知問題](#focus) |
| 長時間掛機、睡眠喚醒 | [8. 日常維護建議](#daily) |
| 檢查目前環境 | [9. 唯讀檢查指令碼](#diagnostics) |

## 核心名詞

| 名詞 | 簡要說明 |
| --- | --- |
| 包裝器（Wrapper） | macOS 上的 `.app` 程式套件，裡面封裝了 Wine 和 Windows 程式。 |
| Wine / Wine prefix | Wine 讓 Windows 程式能在 macOS 上執行；prefix 是包裝器內部模擬的 Windows 環境（虛擬 C 槽和登錄檔）。 |
| Winetricks | 往 prefix 裡安裝 Windows 執行階段元件和字型的輔助工具。 |
| DXMT | 把 Direct3D 11 圖形指令轉譯成 Apple Metal 的轉換層。 |
| BepInEx | Unity 遊戲常用的 Mod 載入框架。 |
| Doorstop | Mod 的入口工具。它以 `winhttp.dll` 的身分在遊戲啟動時被載入，再把 BepInEx 帶進遊戲。 |
| 原生 DLL / 託管 DLL | 原生 DLL（如 `winhttp.dll`）必須和遊戲同為 64 位元；託管 DLL（C# 寫的 BepInEx 與 Mod 外掛）大多不區分位元數。 |

<a id="install"></a>

## 1. 建立 Windows 版 Steam 包裝器

準備：

- Apple Silicon Mac，macOS 14 或更新版本，已安裝 Rosetta 2；
- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)（Creator 與 Template 選用最新版，本機驗證為 Creator `1.0.2` / Template `1.0.22`）；
- 個人 Steam 帳號中已購買的[《活俠傳》](https://store.steampowered.com/app/1859910/Legend_of_Mortal/)；
- 足夠的磁碟空間（包裝器、Steam、遊戲本體約 12 GB，另需備份空間）。

用 Sikarugir Creator 建立獨立包裝器（例如 `SteamWin.app`），然後在它自己的 Wine prefix 中依序：

1. 初始化 prefix，確認同時有 `Program Files` 與 `Program Files (x86)`；
2. 透過 Winetricks 安裝 `cjkfonts`；
3. 設定登錄檔 `hidewineexports=enable`；
4. 安裝 Windows 版 Steam，並把啟動目標設為 `C:\Program Files (x86)\Steam\steam.exe`；
5. 登入 Steam，下載 AppID `1859910`。

macOS 原生 Steam 和 Windows 版 Steam 可以共存。登入或連線異常時，先徹底結束另一端的用戶端，避免同一帳號的工作階段互相擠掉。

### 確認遊戲是 64 位元

在 macOS 終端機執行（把 `/path/to/LegendOfMortal` 換成實際遊戲資料夾）：

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

1.06 的結果：

```text
PE32+ executable (GUI) x86-64, for MS Windows
```

`PE32+` / `x86-64` 表示 64 位元。後面所有**原生**元件（`winhttp.dll`、DXMT 模組）都要選 64 位元版本。如果顯示的是 `PE32` / `Intel 80386`，代表你仍是 1.05，請看 [1.05 歷史設定](#legacy)。

<a id="upgrade"></a>

## 從 1.05 升級到 1.06

1.06 把 `Mortal.exe` 與 `UnityPlayer.dll` 從 32 位元改成了 64 位元。照舊版指南裝過的 Mod 入口 `winhttp.dll` 仍是 32 位元，64 位元遊戲會略過它，改用 Wine 內建的 `winhttp.dll`，於是 **遊戲能啟動，但所有 Mod 同時失效**。只需要換掉這一個檔案。

> 實際操作只換 `winhttp.dll`。`doorstop_config.ini`、`BepInEx/unstripped_corlib`、`BepInEx/core`（be.785）、DiceMaster、存檔擴充等託管外掛**全部保留**。不要因為遊戲換成 64 位元就整套替換 BepInEx。
{: .callout .warn}

1. **存檔並結束**：在遊戲內存檔結束，再從 Windows 版 Steam 選單 `Steam → Exit` 結束。
2. **備份**：複製遊戲資料夾中的 `winhttp.dll`、`doorstop_config.ini` 和整個 `BepInEx` 資料夾到帶時間戳記的資料夾；另外單獨複製一份存檔（`drive_c/users/<使用者名稱>/AppData/LocalLow/Obb Studio/Mortal`）。
3. **確認位元數**：
   ```bash
   file "/path/to/LegendOfMortal/Mortal.exe"
   file "/path/to/LegendOfMortal/winhttp.dll"
   ```
   若前者是 `PE32+ … x86-64`、後者是 `PE32 … Intel 80386`，就是本問題。
4. **換入 x64 Doorstop**：從 [UnityDoorstop 4.4.0 發布頁](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0) 下載 Windows 版，取其中 **x64** 資料夾的 `winhttp.dll`，覆蓋遊戲根目錄的同名檔案。
5. **確認 DLL override 仍在**：在包裝器的 `winecfg` 中，Applications 分頁選 `Mortal.exe`，Libraries 分頁裡應有 `winhttp = native,builtin`。
6. **啟動並查看本次記錄檔**：開啟 `BepInEx/LogOutput.log`，先確認修改時間晚於本次啟動（舊記錄檔會造成誤判），再確認包含：
   ```text
   Process bitness: 64-bit (x64)
   Chainloader initialized
   Chainloader startup complete
   ```
7. **在遊戲裡實際確認功能**：記錄檔出現 `Loading [外掛名稱]` 只代表外掛開始載入，功能能不能用要進遊戲檢查。

本機照此步驟修復後，DiceMaster `1.0.0` 與存檔擴充 `1.2.0` 均恢復載入；存檔擴充已確認可用，DiceMaster 的選項收益提示已確認顯示。DiceMaster 的數值準確性、新劇情解析和擲骰控制仍待驗證。

**選用：同時升級執行元件。** 本機在同一天把包裝器從 Template `1.0.11` / Wine `10.0` 升級到 Template `1.0.22` / Wine `10.0 revision 8`。這一步和修 Mod 入口無關，建議分開做、分開備份，方便判斷是哪一步出了問題。Wine `11.0 revision 1` 在本機卡在 `wineboot` 初始化，暫不推薦。

完整排查過程、驗證範圍和還原方法見 [1.06 升級案例](cases/game-1.06.zht.md)。

<a id="graphics"></a>

## 2. 修復 D3D11 圖形初始化失敗

典型症狀：Steam 顯示「執行中」後遊戲很快結束，或 `Player.log` 中出現：

```text
Failed to initialize graphics.
d3d11: failed to create device and context (80004005)
```

1. 開啟包裝器設定，在圖形設定中開啟 DXMT；
2. 啟動遊戲，確認能進入主選單。

若開啟後仍報錯，先用 `WINEDEBUG=+loaddll` 記錄檔確認 DXMT 是否真的被載入。只有確認沒被載入時，才手動替換 Engine 中的模組：

1. 從記錄檔確認實際生效的 Engine 資料夾；
2. 備份原有的 64 位元 WineD3D 模組並記錄 SHA-256；
3. 把對應版本的 DXMT 模組（`d3d10core.dll`、`d3d11.dll`、`dxgi.dll`、`winemetal.dll`）放入 `x86_64-windows` 資料夾；
4. 把相符的 `winemetal.so` 放入 `x86_64-unix` 資料夾；
5. 記錄替換後的 SHA-256。

成功時 `Player.log` 會顯示：

```text
Direct3D:
    Version:  Direct3D 11.0 [level 11.1]
    Renderer: Apple <GPU>
```

日常啟動建議用 `steam.exe -applaunch 1859910`。

<a id="retina"></a>

## 3. Retina 與解析度

Wine Retina 模式的登錄檔項目：

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

Retina 與遊戲 UI 縮放是兩回事，《活俠傳》的 UI 基本不理會 Windows DPI 設定。解析度越高畫面越清晰、UI 越小；解析度低則 UI 大但會模糊。建議讓遊戲記住自己選的解析度（本機為 `1920×1200`），並從啟動參數中去掉強制的 `-screen-width` / `-screen-height`。

<a id="fonts"></a>

## 4. 修復商店價格顯示空白

症狀：中文對話、一般數值和銅錢圖示都正常，只有商店的單價與總額是空白。

1. 徹底結束 Windows 版 Steam；
2. 備份 `drive_c/windows/Fonts`、`system.reg`、`user.reg`、`userdef.reg`；
3. 開啟 Winetricks，安裝 `fonts → allfonts`；
4. 重新啟動包裝器，啟動遊戲確認商店金額顯示正常。

<details markdown="1">
<summary>原因與測試記錄</summary>

`MoneyValue` / `MoneyText` 元件使用內嵌字型 `SourceHanSerifTC-Bold`，字型圖集也包含 `0–9`，問題出在 prefix 的字型集合與字型對應不完整。初始 prefix 只有 `sourcehansans.ttc` 和 `unifont.ttf`；安裝 `allfonts` 後增至 121 個檔案（約 284 MB），數量因環境而異。

各字型有各自的授權條款。請透過 Winetricks 從原始來源安裝；本存放庫不散布任何字型。

</details>

<a id="mods"></a>

## 5. 安裝與修復 BepInEx Mod

### 載入流程

1. **Doorstop**：Wine 載入遊戲資料夾裡的 `winhttp.dll`，由它啟動 BepInEx Preloader；
2. **Preloader**：載入 Unity 基礎函式庫（corlibs）並準備環境；
3. **Chainloader**：依序載入 `BepInEx/plugins/` 下的 Mod。

三個環節在 Wine 下各有一個坑，對應下面三步。已經在 1.05 時期裝好、只是升級到 1.06 的玩家，只需看 [從 1.05 升級到 1.06](#upgrade)。

### 安裝前的檢查

對每個 Mod 壓縮檔：

1. 檢查檔內路徑，排除絕對路徑和 `..`；
2. 用 `file` 確認 `winhttp.dll` 等原生 DLL 是 64 位元（`PE32+`）；
3. 列出會被覆蓋的檔案，先複製到帶時間戳記的備份資料夾；
4. 解壓縮後核對 SHA-256；
5. 啟動後確認 `LogOutput.log` 是本次啟動產生的。

> 含日文檔名的壓縮檔請用 Finder 或 `ditto -x -k` 解壓縮。macOS 內建的 `unzip` 會在日文檔名處報錯並留下殘缺檔案。
{: .callout}

### 第一步：讓 Wine 載入 Doorstop

Wine 預設優先用內建的 `winhttp.dll`。在 `winecfg` 的 Applications 分頁選 `Mortal.exe`，再到 Libraries 分頁新增：

```text
winhttp = native,builtin
```

遊戲資料夾中的 `winhttp.dll` 必須是 64 位元。本機驗證的是 [UnityDoorstop 4.4.0](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0) Windows **x64** 版。

### 第二步：提供完整 corlibs

遊戲內建的 `Mortal_Data/Managed/mscorlib.dll` 是裁剪版（`3,906,048` 位元組）；Unity `2020.3.49f1` 的完整版為 `4,065,792` 位元組。把合法取得、版本一致的完整 corlibs 放入 `BepInEx/unstripped_corlib/`，並編輯 `doorstop_config.ini`：

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

corlibs 必須與 Unity 版本完全一致，並遵守 Unity 的授權條款；本存放庫不散布 corlibs。1.06 下是否仍為必要尚未單獨驗證，本機驗證的設定保留了它。

### 第三步：使用包含 Wine 修復的 BepInEx 6

舊版 BepInEx 6（如 `be.692`）在 Wine 下可能擲出：

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

該問題見 [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)，已在 [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254) 修復。請先備份 `BepInEx/core`，再換成 `6.0.0-be.785` 的 Unity.Mono 核心。

本機實際使用的是 be.785 託管核心 + Doorstop 4.4.0 x64 `winhttp.dll`。託管核心不區分位元數，所以 1.05 時期裝的 be.785 在 1.06 下可以繼續使用；全新安裝可以直接用 BepInEx 的 win-x64 套件，但請確認套件內的 `winhttp.dll` 是 64 位元。

成功時記錄檔包含：

```text
BepInEx 6.0.0-be.785
Process bitness: 64-bit (x64)
Chainloader initialized
```

<a id="jpmod"></a>

## 6. 日文 Mod v2.5

日文 Mod v2.5 已改為針對 64 位元遊戲，並加入了遊戲內更新功能。它的 README 要求「全部覆蓋」，但在 Mac 上整包覆蓋會把 BepInEx 核心換回舊的 `be.692`，`doorstop_config.ini` 也會失去 `unstripped_corlib` 路徑。

**已實測（2026-10-15）：** 依 README 全部覆蓋後，只需兩步：① 把 `BepInEx/core` 換回覆蓋前的 be.785；② 把 `doorstop_config.ini` 改為 `dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"`。之後日文 Mod、DiceMaster 與存檔擴展共 8 個外掛全部載入、無錯誤；v2.5 內附的 64 位元 `winhttp.dll` 可直接使用。只覆蓋不修改時，be.692 會以 `PlatformHelper.Current` 錯誤中止，所有 Mod 失效。

Mac 上的安裝步驟和驗證結果見日文頁面：[日本語化 Mod v2.5 を Mac で導入する](cases/japanese-mod-v2.5.ja.md)。

<a id="focus"></a>

## 7. 已知問題：切換視窗後需點一下標題列

從其他 macOS 應用程式切回《活俠傳》後，畫面正常更新，但鍵盤、滑鼠或手把可能沒有反應。

1. 切回 `Mortal` 遊戲視窗；
2. 點一下視窗頂端的深色標題列（下圖紅色箭頭處）；
3. 回到遊戲繼續操作。

![點一下 Mortal 視窗標題列以恢復遊戲輸入](assets/window-titlebar-focus-recovery.png)

關閉 Steam 全域 Overlay 與本遊戲的 Overlay 可以降低發生頻率。這個現象在 1.05 實機重現並確認解決方法；1.06 下尚未專門複測。根本原因仍在排查，符合 Wine、Unity 與 macOS 之間焦點傳遞異常的特徵。

<a id="daily"></a>

## 8. 日常維護建議

- 關閉 Steam 全域 Overlay 和本遊戲的 Overlay。
- 遊玩時可用 `caffeinate` 防止系統睡眠。闔上螢幕睡眠、鎖定畫面或插拔外接顯示器後，建議存檔並重新啟動遊戲、Steam 和包裝器。
- 結束時先在遊戲內存檔，再用 Windows 版 Steam 的 `Steam → Exit`。Dock 裡的 Wine 圖示只是視窗代理。
- Windows 版 Steam 長時間掛在背景後可能不再回應 `-applaunch`。若 `gameprocess_log.txt` 沒有新記錄，請重新啟動本包裝器的 Steam 與 Wine 工作階段。

<a id="diagnostics"></a>

## 9. 唯讀檢查指令碼

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

指令碼只讀取包裝器設定、遊戲架構、Steam 清單、登錄檔、字型數量、DXMT 模組雜湊值、BepInEx 記錄檔和目前的處理程序，不會啟動或結束任何處理程序，也不修改檔案。指令碼在[專案存放庫](https://github.com/li-yifei/legend-of-mortal-mac-guide)中。

## 讓 AI 助理協助

不熟悉 Wine 或終端機的讀者，可以把本指南交給 AI 程式設計助理，讓它先唯讀檢查本機環境，再依症狀處理。請遵守：

- Steam 由自己手動登入，不向 AI 提供帳號密碼或權杖；
- 檔案替換和有風險的指令先由人工確認；
- 修改 Engine、prefix 或遊戲資料夾前先做帶時間戳記的備份。

<a id="legacy"></a>

## 1.05 歷史設定

<details markdown="1">
<summary>1.05（Build <code>20337760</code>，32 位元）的驗證環境與差異</summary>

2026-08-29 驗證：

| 項目 | 設定 |
| --- | --- |
| 遊戲 | Build `20337760`，`release_1.0.5000.13` |
| 遊戲程式 | `Mortal.exe`，PE32 / x86 |
| 包裝器 | Sikarugir Template `1.0.11`，Wine `10.0` |
| 圖形後端 | 32 位元 DXMT |
| Mod | Doorstop x86 `winhttp.dll`，BepInEx `6.0.0-be.785` x86 Mono |

與 1.06 的差異：

- `file Mortal.exe` 顯示 `PE32 executable (GUI) Intel 80386`；
- 原生元件全部選 32 位元：`winhttp.dll` 用 x86 版，手動替換 DXMT 時放入 `i386-windows` / `i386-unix`；
- D3DMetal 只涵蓋 64 位元，不能用於 1.05；DXMT 提供 32 位元 D3D10/11 模組；
- 日文 Mod v2.4 與 DiceMaster 的載入過程見 [日文 Mod v2.4 案例](cases/japanese-mod.zhs.md)（簡體中文）。

</details>

## 參考資料

- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)
- [DXMT](https://github.com/3Shain/dxmt)
- [UnityDoorstop 4.4.0](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0)
- [BepInEx Wine 修復（PR #1254）](https://github.com/BepInEx/BepInEx/pull/1254)
- [《活俠傳》日文 Mod](https://dlaqe2334.github.io/LOM-JPMOD/)
