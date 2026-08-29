---
layout: page
title: ケース：Wine 10 / x86版『活俠傳』で日本語化Modを読み込む
permalink: /docs/cases/japanese-mod.ja/
---

[日本語ガイドへ戻る](../guide.ja.md) · [繁體中文](../guide.zht.md) · [简体中文](japanese-mod.zhs.md) · [한국어](japanese-mod.ko.md)

## 結論

macOS環境においてWine 10.0を経由して32ビット（x86）版『活俠傳』を実行する場合、日本語化Mod v2.4およびDiceMasterをゲームディレクトリに展開しても既定では読み込みに失敗します。この原因は、**WineのDLLオーバーライド未適用**、**ゲーム同梱corlibsのストリップ（削減）によるPreloaderの停止**、および**旧版BepInEx 6のWine環境下におけるプラットフォーム初期化例外**という3つの障害要因が連鎖しているためです。

アプリケーション個別の`winhttp` overrideの設定、Unity `2020.3.49f1`に完全一致する未ストリップ版corlibsの配置と探索パス設定、およびWine初期化修正を取り込んだBepInEx `6.0.0-be.785`（x86 Mono）への更新を実施することでロードチェーンが正常化し、Chainloaderによって5個のプラグインすべてが読み込まれ、72,977行の日本語テキストのインジェクションが完了します。

なお、同環境で動作不能となっていた**DiceMaster Mod**についても、基盤となるBepInExランタイム環境が同一であるため、**本ケースとまったく同じDoorstop / corlibs / BepInEx Wine修復手順を適用することで正常にロード・動作します**。

## 適用条件

| 項目 | 適用 / 検証条件 |
| --- | --- |
| ゲームバージョン | Steam AppID `1859910`、Build ID `20337760`（`release_1.0.5000.13`） |
| Unityエンジン | `2020.3.49f1` |
| プロセスアーキテクチャ | `Mortal.exe`、PE32 / x86（32ビット） |
| 動作環境 | Sikarugir Wine `10.0`（64ビットPrefix / 32ビットDXMT） |
| 対象Mod | [日本語化Mod v2.4](https://dlaqe2334.github.io/LOM-JPMOD/)、DiceMaster 1.0.0 |
| BepInExバージョン | 当初 `6.0.0-be.692` → 修正検証版 `6.0.0-be.785` x86 Mono |
| 検証日 | 2026-08-29 |

## 最短修復手順

1. **DLL Overrideの設定**：`winecfg`のライブラリ（Libraries）タブで、`Mortal.exe`に対して`winhttp = native,builtin`を追加する。
2. **未ストリップ版corlibsの配置**：Unity `2020.3.49f1`の完全な未ストリップ版corlibsを`BepInEx/unstripped_corlib/`へ配置し、`doorstop_config.ini`に`dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"`を設定する。
3. **BepInEx Coreの更新**：`BepInEx/core`をWine初期化修正（PR #1254）適用済みのx86 Monoビルド**`6.0.0-be.785`**に一式差し替える（エントリポイントは既定の`Application::.cctor`を維持）。
4. **ゲーム内言語の設定**：ゲームを起動し、設定メニューでゲーム内言語を「簡体字中国語（简体中文）」に設定する。

## 成功判定基準

- [x] **ログの正常出力**：`BepInEx/LogOutput.log`に`BepInEx 6.0.0-be.785`、`Process bitness: 32-bit (x86)`、`Chainloader initialized`が出力されていること。
- [x] **全プラグインのロード完了**：5個のプラグイン（`plugin by Binarizer 1.0.0`、`DiceMaster 1.0.0`、`LOM JP Font Patch 0.2.44`、`LOM JP Ruby Prototype 0.15.113`、`LOM JP String Vault 0.1.0`）がエラーなくロードされていること。
- [x] **日本語表示とショートカット動作**：ゲーム内テキスト72,977行が正常に置換表示され、`F5`キーでルビ表示切り替え、`F7`キーで表示モード切り替えが機能すること。
- [x] **DiceMasterの正常動作**：DiceMasterのコンソールおよび機能がゲーム内で正常に呼び出せること。

---

## 1. 問題の現象と根本原因

### 問題の現象

日本語化Mod v2.4やDiceMasterのアーカイブを展開してゲームディレクトリに配置しても、以下の不具合が発生します。
- ゲーム自体は起動するもののModが一切適用されず、テキストが中国語のままでMod画面も表示されない。
- `BepInEx/LogOutput.log`が生成されない・更新されない、またはPreloader段階で静かに処理が中断する。
- デバッグ出力やコンソールを有効にしている場合、初期化処理中に`PlatformHelper.Current`例外が発生してプロセスが停止する。

### 根本原因の分析

Modの読み込み失敗は、以下の3層の技術的要因が連鎖して発生しています。
1. **Doorstopインジェクションの無効化**：Wineの既定動作では内部（builtin）の`winhttp.dll`が優先されるため、ゲームディレクトリに置かれたネイティブ（native）のDoorstopプロキシDLLが無視され、Preloaderが起動しません。
2. **corlibsのストリップ（削減）**：ゲーム本体に同梱されている`mscorlib.dll`（約3.90 MB）は型情報やメタデータが削減されており、BepInEx Preloaderのリフレクション処理に必要な定義が不足しているため、初期化処理が中断します。
3. **BepInEx 6のWine環境初期化バグ**：旧ビルド（`6.0.0-be.692`など）では、Wine 32ビット環境でのプラットフォーム判定処理に不具合があり、読み取り専用プロパティへの多重代入による例外が送出されます。

<details>
<summary>技術詳細：例外スタックトレースと呼び出しフロー</summary>

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
  at BepInEx.PlatformHelper.set_Current (BepInEx.PlatformHelper+Platform value)
  at BepInEx.Unity.Mono.Preloader.Preloader.Run ()
```

- **課題トラッキング**：[BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)にて報告され、[PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)にて修正されました。
- **Doorstopフックの仕組み**：Windows版Unityプロセスは起動時に`winhttp.dll`をロードします。Doorstopは同名DLLフックによってUnity Monoランタイムの初期化直前にPreloaderを割り込ませ、Chainloaderを経由して各プラグインDLLを読み込みます。

</details>

---

## 2. トラブルシューティングの事前確認と診断

修復作業を開始する前に、以下の項目を確認します。

1. **プロセスアーキテクチャの確認**：`Mortal.exe`が32ビット（PE32 / x86）バイナリであることを確認する。
2. **DLL Overrideの登録状態**：Wine prefixのレジストリまたは`winecfg`で`Mortal.exe`に対する`winhttp`の設定有無を確認する。
3. **corlibsの整合性確認**：ゲームディレクトリ内の`mscorlib.dll`と未ストリップ版のファイルサイズを比較する。
4. **BepInEx Coreバージョンの確認**：`BepInEx/core`内のバイナリがWine初期化修正版であるかを確認する。
5. **Modアーカイブの安全性確認**：展開前にアーカイブ内に絶対パスや`..`を含むパストラバーサル（Path Traversal）構造がないこと、およびネイティブDLLがx86向けであることを確認する。

<details>
<summary>技術詳細：アーカイブのセキュリティ確認とファイル比較リスト</summary>

- **ファイルサイズ比較**：
  ```text
  ゲーム同梱 mscorlib.dll       3,906,048 bytes (ストリップ版 / Stripped)
  Unity 2020.3.49 完全版        4,065,792 bytes (未ストリップ版 / Unstripped)
  ```
- **ライセンスとセキュリティ境界**：corlibsはUnityエンジンのバージョン（`2020.3.49f1`）と厳密に一致させる必要があります。Unityソフトウェア利用規約を遵守し、正規の手段で取得してください。公開リポジトリや配布パッケージはフォント・corlibsの再配布を行わない原則を維持します。
- **整合性ハッシュ検証**：上書き展開を行う前に、既存のDiceMaster DLLおよび設定ファイルのSHA-256ハッシュ値を記録・退避し、統合時の破損を防ぎます。

</details>

---

## 3. 段階的な修復手順

### 手順 1：アプリケーション個別DLL Overrideを設定する

対象Wine prefixの`winecfg`を起動します。
1. **ライブラリ（Libraries）** タブを選択します。
2. **アプリケーション設定（Applications）** で`Mortal.exe`を追加して選択します。
3. **新規オーバーライド（New override for library）** に`winhttp`と入力して追加します。
4. 読み込み順序が以下になっていることを確認します。
   ```text
   winhttp = native,builtin
   ```

### 手順 2：Unity 2020.3.49f1未ストリップ版corlibsの配置とDoorstop設定

1. ゲームディレクトリの`BepInEx`内に`unstripped_corlib`ディレクトリを作成します。
   ```text
   BepInEx/unstripped_corlib/
   ```
2. Unity `2020.3.49f1`に完全一致する未ストリップ版corlibs一式を配置します。
3. ゲーム直下の`doorstop_config.ini`を作成または編集し、以下を設定します。
   ```ini
   [General]
   enabled = true
   target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

   [UnityMono]
   dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
   ```

### 手順 3：BepInEx Coreを修正版（6.0.0-be.785）へ更新する

1. 既存の`BepInEx/core`ディレクトリを一括バックアップします。
2. `BepInEx/core`をPR #1254の修正を含むx86 Monoビルド**`6.0.0-be.785`**の一式に差し替えます。
3. マネージドエントリポイントは既定の`Application::.cctor`のままとします。

### 手順 4：ゲーム内言語を設定する

1. ゲームを起動してメインメニューの設定を開きます。
2. 言語設定を**「簡体字中国語（简体中文）」**に切り替えます（日本語化Modは簡体字中国語のテキストパイプラインにフックします）。

<details>
<summary>技術詳細：Doorstop設定項目とMonoアセンブリ探索機構</summary>

- `dll_search_path_override`パラメータにより、Monoランタイムがコアアセンブリを読み込む際に`BepInEx\unstripped_corlib`を最優先で探索し、`Mortal_Data\Managed`内のストリップ版アセンブリを上書き参照します。
- 既定エントリポイントの`Application::.cctor`は、Unityエンジンの`UnityEngine.Application`クラスの静的コンストラクタ実行時にPreloaderをフックするため、高い互換性と安定性を発揮します。

</details>

---

## 4. 動作検証とプラグイン確認

### 1. 起動ログの確認

ゲーム起動後、`BepInEx/LogOutput.log`を開いて以下の出力が含まれていることを確認します。

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

### 2. プラグイン読み込み一覧の確認

Chainloaderによって全5個のプラグインが正常にロードされ、Error/Fatalログが発生していないことを確認します。

```text
plugin by Binarizer 1.0.0
DiceMaster 1.0.0
LOM JP Font Patch 0.2.44
LOM JP Ruby Prototype 0.15.113
LOM JP String Vault 0.1.0
```

### 3. ゲーム内表示とショートカットキーの検証

- **テキストインジェクション**：ゲーム内に入り、UIおよび会話テキストが日本語に置換されていること（72,977行の注入成功）を確認します。
- **ショートカットキー**：
  - **`F5`**：人名のルビ（振仮名）表示の切り替え。
  - **`F7`**：表示モードの切り替え。

### 4. DiceMasterおよび複数Modの共存

**DiceMaster Mod**は日本語化Modと同一のBepInEx 6基盤上で動作します。Wine環境でDiceMasterを単体で導入した場合に発生する問題（`winhttp`未フック、corlibsストリップによるPreloader停止、BepInExプラットフォーム例外）は完全に同一です。そのため、**本修復手順を適用することで、DiceMasterも日本語化Modと同時に正常にロード・動作します**。

<details>
<summary>技術詳細：ロード検証ログの完全出力</summary>

```text
[Message:   BepInEx] BepInEx 6.0.0-be.785 - Mortal
[Info   :   BepInEx] System platform: Windows 10 (Wine 10.0) 64-bit
[Info   :   BepInEx] Process bitness: 32-bit (x86)
[Message:   BepInEx] Preloader started
[Info   :   BepInEx] Loaded 1 patcher method from [BepInEx.Preloader 6.0.0.785]
[Info   :   BepInEx] 1 patcher result: 1 patch applied
[Message:   BepInEx] Preloader finished
[Message:   BepInEx] Chainloader ready
[Message:   BepInEx] Chainloader initialized
[Info   :   BepInEx] Loading [plugin by Binarizer 1.0.0]
[Info   :   BepInEx] Loading [DiceMaster 1.0.0]
[Info   :   BepInEx] Loading [LOM JP Font Patch 0.2.44]
[Info   :   BepInEx] Loading [LOM JP Ruby Prototype 0.15.113]
[Info   :   BepInEx] Loading [LOM JP String Vault 0.1.0]
```

</details>

---

## 5. ロールバック境界と安全対策

### 3段階のロールバック境界

不具合発生時に状態を復元できるよう、以下の段階別ロールバック手順を定めます。

1. **段階 1：Mod導入前の状態へ復元**
   - ゲームディレクトリ下の`BepInEx`、`doorstop_config.ini`、`winhttp.dll`およびModリソース群を削除する。
   - 事前にバックアップしたオリジナルゲームファイルを書き戻す。
2. **段階 2：corlibs設定前の状態へ復元**
   - `BepInEx/unstripped_corlib`ディレクトリを削除する。
   - `doorstop_config.ini`の`dll_search_path_override`設定を削除または初期値に戻す。
3. **段階 3：BepInEx Core更新前の状態へ復元**
   - `BepInEx/core`ディレクトリを削除する。
   - バックアップした旧`BepInEx/core`（`be.692`など）を書き戻す。

### 安全操作ルール

- **プロセスの完全終了**：ファイルのバックアップ、書き換え、ロールバックを行う前に、必ずゲーム、Windows版Steam、および対象prefixのwineserverプロセスを終了（`wineserver -k`）してください。
- **一括アトミック復元**：`BepInEx/core`の差し替え・復元時はディレクトリごと一式で操作し、異なるバージョンのDLLを混在させないでください。
- **認証情報の隔離**：Mod導入およびトラブルシューティング作業において、Steamのアカウント情報やログイン認証情報には一切触れません。

<details>
<summary>技術詳細：wineserverプロセス管理とセキュリティ境界</summary>

- **Wineセッションの終了コマンド**：
  ```bash
  wineserver -k
  ```
- **プロセス解放確認**：`Mortal.exe`、`Steam.exe`、`wineserver`の残存プロセスが存在しないことを確認した上でファイルの操作を行ってください。
</details>
