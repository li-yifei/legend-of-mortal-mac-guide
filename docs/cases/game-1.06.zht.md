---
layout: page
title: "《活俠傳》1.06 更新後 Mod 失效：先檢查 64 位元入口"
permalink: /docs/cases/game-1.06.zht/
---

[返回繁體中文指南](../guide.zht.md) · [简体中文](game-1.06.zhs.md) · [日本語](game-1.06.ja.md) · [한국어](game-1.06.ko.md)

2026 年 10 月 15 日實測：更新至遊戲 1.06、Steam Build `25953419` 後，遊戲可正常啟動，但 DiceMaster 與存檔擴展卻沒有效果。檢查發現，遊戲主程式已從 32 位元升級為 64 位元，而負責將 Mod 框架注入遊戲的 Doorstop 入口工具仍停留在舊的 32 位元版本。

本次換用 Doorstop `4.4.0` 的 Windows x64 `winhttp.dll`，保留原有 BepInEx `6.0.0-be.785`、DiceMaster `1.0.0` 與存檔擴展 `1.2.0`，隨後恢復了外掛模組載入。存檔擴展已有玩家確認可用，DiceMaster 的選項收益提示已有截圖確認顯示。**日文 Mod 在 1.06 環境下的相容性仍待單獨驗證。**

## 先判斷是否屬於這個問題

適合參考本案例的情況是：遊戲更新後可以進入主選單，但原本可用的 Mod 同時失效。若曾按照舊版指南安裝過 32 位元 Doorstop，應優先檢查遊戲主程式與入口 DLL 的位元架構。

| 要檢查的檔案 | 本次更新後的實際結果 | 含義 |
| --- | --- | --- |
| `Mortal.exe`、`UnityPlayer.dll` | PE32+ / x86-64 | 遊戲主程式已變為 64 位元 |
| 原有 `winhttp.dll` | PE32 / x86 | 仍是舊的 32 位元 Doorstop 入口，需要更換 |
| BepInEx、DiceMaster、存檔擴展 | 託管組件（.NET DLL），未設定 `Requires32Bit` | 本次保留後已在 64 位元遊戲中正常載入；切勿因遊戲架構改變而盲目替換託管核心 |

Doorstop 使用遊戲目錄裡的 `winhttp.dll` 在啟動時載入 BepInEx（Unity Mod 框架）；BepInEx 再載入各個 Mod。原生 DLL 必須與 `Mortal.exe` 的位元架構完全相符，而託管外掛程式（C# 編寫的 Mod 組件）則需結合其自身相容性與實際功能進行驗證，不必全盤更換。

## 修復順序

### 1. 退出遊戲並備份

正常存檔並退出遊戲，再退出封裝器（Wrapper，即 macOS 上的 Wine 執行環境）內的 Windows 版 Steam。若需要結束 Wine 工作階段，僅處理本遊戲所在的封裝器。

備份遊戲目錄中的 `winhttp.dll`、`doorstop_config.ini` 與完整 `BepInEx` 目錄；記錄檔案版本與 SHA-256 雜湊值。需要同時升級執行環境組件時，再單獨備份整個封裝器。本次實測使用了完整封裝器備份。

### 2. 確認遊戲和 DLL 的位元數

在 macOS 終端機中執行下方兩條唯讀指令。將 `/path/to/LegendOfMortal` 替換為個人遊戲目錄的完整路徑。

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
file "/path/to/LegendOfMortal/winhttp.dll"
```

本次修復前，遊戲主程式顯示 `PE32+` / `x86-64`（64 位元），而 `winhttp.dll` 顯示 `PE32` / `Intel 80386`（32 位元）。這個位元架構不一致是本次入口注入失效的原因。

### 3. 更換為 Windows x64 Doorstop

從 [UnityDoorstop 4.4.0 官方發布頁面](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0) 取得 Windows 版本，解壓縮後核對 x64 `winhttp.dll`，再替換遊戲根目錄中的同名檔案。透過 Wine 執行的遊戲必須使用 Windows 版 DLL。

這次保留了原有的 `doorstop_config.ini`、完整 corlibs（Unity 核心相依庫）與 BepInEx 託管核心。原有的 BepInEx、DiceMaster 與存檔擴展皆未設定強制 32 位元旗標，在本次 64 位元啟動中皆已成功載入。切勿因遊戲架構改變而盲目替換託管核心。其他版本的外掛模組仍需逐一核驗。

在封裝器的 `winecfg` 中，先在 **Applications** 分頁選取 `Mortal.exe`，再至 **Libraries** 分頁確認該遊戲專用設定：

```text
winhttp = native,builtin
```

此設定讓 Wine 優先使用遊戲目錄內的 Doorstop 原生檔案。Unity 引擎版本維持不變，仍為 `2020.3.49f1`，本次繼續沿用相符版本的 corlibs。遊戲更新後，Unity 版本亦應重新確認。

### 4. 用本次啟動的日誌檢查載入

啟動遊戲後，確認 `BepInEx/LogOutput.log` 的修改時間晚於本次遊戲啟動時間。舊日誌曾在本次排查中造成誤判：日誌停在 16:12，而遊戲已於 16:14 重新啟動。

修復後在 16:25 的啟動日誌包含：

```text
Process bitness: 64-bit (x64)
Chainloader initialized
Loading [DiceMaster 1.0.0]
Loading [LOM Save Slot Expander 1.2.0]
Chainloader startup complete
```

`Process bitness: 64-bit (x64)` 確認當前處理程序為 64 位元；`Chainloader initialized` 確認框架已啟動；每個 `Loading [...]` 項目確認對應外掛模組已進入載入程序。最後仍須在遊戲內實際檢查各項功能。

## 本次驗證到了哪裡

### 日文 Mod v2.5 的補充

同日更新的日文 Mod v2.5 已完成套件靜態分析：安裝包內附帶 64 位元 Doorstop（版本標記 `4.3.0`）、分版本管理的執行元件與翻譯資料，以及新的排版處理。但套件內的 BepInEx 核心仍為 `be.692`，若直接整包覆蓋，會替換掉本機已驗證可用的 `be.785`。建議玩家在嘗試前先完整備份現有環境，再依序確認框架初始化、新外掛載入與日文顯示。需要說明的是，本案例中 Doorstop `4.4.0` 的啟動成果屬於本機獨立修復，不能視為 v2.5 的執行依據；v2.5 在 macOS 上的實際執行結果仍待驗證。

### 已確認與待驗證項目

| 項目 | 條件與結果 | 證據與置信度 |
| --- | --- | --- |
| 遊戲與 Mod 框架啟動 | Build `25953419`、x64 Doorstop、新日誌顯示 x64 與 Chainloader 完成 | 當前處理程序模組與本次啟動日誌；高 |
| 存檔擴展 `1.2.0` | 玩家確認存檔擴展功能可用 | 玩家實際操作確認；高，僅限已確認功能 |
| DiceMaster `1.0.0` 選項資訊 | 選項收益提示恢復顯示 | 玩家遊戲截圖；高，僅限提示顯示；數值準確性與新劇情解析待驗證 |
| DiceMaster 選單 | 本機快捷鍵配置為 `F10`（本地自訂快捷鍵，非通用預設快捷鍵），內建鍵盤可用 `Fn + F10` | 本地快捷鍵配置已確認，選單互動待驗證 |
| 日文 Mod | 1.06 環境下未進行測試 | 待驗證 |
| 字型外觀、視窗切換、睡眠喚醒、長時間遊玩 | 本輪僅完成啟動、圖形與音訊初始化檢查 | 待後續遊玩驗證；舊版結論保留於歷史指南中 |

驗證 DiceMaster 時，建議選擇一個收益明確的新劇情選項，比對選擇前後的實際屬性變化；並測試一個新擲骰事件及對應分支。提示能否正常顯示、數值是否準確、擲骰控制是否生效，屬於需要分別確認的不同項目。本輪驗證尚未確認新劇情解析、數值準確性、擲骰控制、特殊結算以及 F10 選單互動的完整相容性。

## 同時升級的運行組件

以下是本機最終採用的組件組合，驗證日期為 2026 年 10 月 15 日。修復入口與升級執行環境組件分別記錄，便於判斷每次變動的具體影響。

| 組件 | 本次最終配置 |
| --- | --- |
| 遊戲 | Steam AppID `1859910`、Build `25953419`、x64 |
| Unity | `2020.3.49f1` |
| Doorstop | `4.4.0` Windows x64 |
| BepInEx | 保留 `6.0.0-be.785` 託管核心 |
| Sikarugir Creator | `1.0.2` |
| 封裝器執行組件 | Template `1.0.22` |
| Wine 引擎 | Sikarugir `10.0 revision 8` |
| DXMT | 新模板配套組建 `v0.80-244-g7c8dee1` |

Steam 登入、遊戲啟動、D3D11 feature level 11.1、音訊初始化與場景載入皆通過。Wine 11.0 revision 1 在本機原有環境與新建空白環境中皆停滯在 `wineboot` 初始化階段，原因尚待釐清，屬於本機特定未決問題；本機最終採用驗證通過的 Wine 10.0 revision 8。此觀察結論僅適用於本次測試環境。

## 需要回退時

先正常退出遊戲、Windows 版 Steam 與本封裝器的 Wine 工作階段，再依層級還原備份。例如僅更換了 Doorstop，只需還原先前的 `winhttp.dll`；若升級了執行環境組件，則依整套備份還原該層組件。

完整封裝器備份亦包含備份當時的遊戲存檔。若在備份後繼續遊玩並產生了新進度，還原整套環境前務必單獨備份新存檔，以免遊戲進度被舊存檔覆蓋，並核對存檔與遊戲版本的相容性。還原 BepInEx 託管核心時，請依完整版本整體處理。

## 官方來源

- [UnityDoorstop 4.4.0](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0)
- [Sikarugir Creator 1.0.2](https://github.com/Sikarugir-App/Creator/releases/tag/v1.0.2)
- [Sikarugir Template 發布頁面](https://github.com/Sikarugir-App/Template/releases/tag/v1.0)
- [Sikarugir Engines 發布頁面](https://github.com/Sikarugir-App/Engines/releases/tag/v1.0)

本文依據 2026 年 10 月 15 日的本機升級記錄、本次啟動日誌與玩家確認整理。原始記錄中的個人路徑、帳號資訊與存檔皆保存在本地。
