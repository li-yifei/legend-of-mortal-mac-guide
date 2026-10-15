---
layout: page
title: Apple Silicon Macで『活俠傳』を動かす：インストール・フォント・Mod修復
permalink: /docs/guide.ja/
---

[ホーム](../README.md) · [繁體中文](guide.zht.md) · [简体中文](guide.zhs.md) · [한국어](guide.ko.md)

> 本文は 2026-08-29、Build `20337760` の旧版で確認した手順です。32bit コンポーネントの選択はこの構成に対応します。ゲーム 1.06（Build `25953419`）の 64bit 起動入口の修復は [1.06 更新事例](cases/game-1.06.ja.md)を参照してください。各機能の確認状況も記載しています。

本書は、Apple Silicon Mac 上で自身が購入した正規版『活俠傳』（Legend of Mortal）をプレイしたいユーザーに向けて、Sikarugir、Wine、Windows 版 Steam を用いた導入手順を解説し、グラフィック初期化エラー、ショップ文字の空白化、Mod 読み込みの失敗といった代表的な問題の対処法をまとめたガイドです。

## 検証済み環境

| 項目 | 検証済み構成 |
| --- | --- |
| ゲーム | Steam AppID `1859910`、Build ID `20337760`、`release_1.0.5000.13` |
| Unity | `2020.3.49f1` |
| 実行ファイル | `Mortal.exe`、PE32 / x86 |
| ラッパー（Wrapper） | Sikarugir Template `1.0.11` |
| Wine | Sikarugir Wine `10.0` |
| グラフィックバックエンド | 32ビット DXMT、D3D11 → Metal |
| Mod フレームワーク | BepInEx `6.0.0-be.785` x86 Mono |
| 最終検証日 | 2026-08-29 |

Wine、Steam、macOS、およびゲーム本体のアップデートはいずれも互換性や動作結果に影響を与える可能性があります。設定を変更する際は、バージョン番号を記録し、タイムスタンプ付きのバックアップを作成してください。

## 症状別の対処インデックス

各修復セクションは、該当する症状が発生した場合にのみ実施してください。ゲームが正常に動作している場合は追加の修復作業は不要です。

| 症状または目的 | 該当セクション | 主な対応内容 |
| --- | --- | --- |
| 初回の環境構築とゲーム導入 | [1. 独立したWindows版Steamラッパーを作成する](#install) | ラッパー作成、Windows 版 Steam とゲームのインストール |
| 起動直後に強制終了 / D3D11エラー | [2. D3D11グラフィック初期化エラーを修復する](#graphics) | DXMT によるグラフィック変換の有効化（必要時に Engine DLL 手動置換） |
| 画面のぼやけ・UIサイズの問題 | [3. Retinaと解像度の設定](#retina) | 必要に応じて RetinaMode を有効化し、見やすい解像度を選択 |
| ショップの単価や合計金額が空白 | [4. ショップの価格および合計金額が空白になる問題の修復](#fonts) | レジストリ退避と Winetricks allfonts によるフォント追加 |
| Mod や日本語化パッチが動かない | [5. DoorstopとBepInEx Modの読み込みを修復する](#mods) | winhttp 設定、未ストリップ corlibs の配置、BepInEx 6 更新 |
| アプリ切替後に入力が受け付けられない | [6. 既知の問題](#focus) | ウィンドウ上部のタイトルバーをクリックして操作権を復帰 |
| 長時間放置やスリープでのクラッシュ予防 | [7. 日常の運用・メンテナンス](#daily) | Overlay 無効化、caffeinate 活用、安全な Steam 終了 |
| 現在の環境設定とログの検査 | [8. リポジトリ同梱の読み取り専用診断スクリプトを使用する](#diagnostics) | 読み取り専用スクリプトによる診断レポート出力 |

## 主要用語の解説

| 用語 | 概要 |
| --- | --- |
| ラッパー（Wrapper / App） | macOS 上で `.app` 形式のアプリケーションバンドルとして、Wine 実行環境と Windows アプリをひとまとめにしたもの。 |
| Wine | Windows アプリが必要とするシステム機能を macOS 上で使えるようにする互換レイヤー。 |
| Wine prefix | ラッパー内に作成される独立した仮想 Windows 環境（仮想 C ドライブやレジストリ）。 |
| Winetricks | Wine prefix に各種ランタイムや Windows フォントを自動導入するための補助スクリプト。 |
| DXMT | Direct3D 11 のグラフィック命令を Apple Metal 向けに変換する描画変換レイヤー。 |
| BepInEx | Unity 製ゲームで広く利用されている Mod プラグイン読み込み・管理フレームワーク。 |
| Doorstop / 読み込みチェーン | Mod 導入時の起点となるツール群。Doorstop が起動直後に介入して Preloader を呼び出し、続いて Chainloader が各 Mod プラグインを読み込みます。 |

<a id="install"></a>

## 1. 独立したWindows版Steamラッパーを作成する

事前準備：
- Apple Silicon Mac（macOS 14 以降）；
- Rosetta 2 環境；
- [Sikarugir 公式プロジェクト](https://github.com/Sikarugir-App/Sikarugir)；
- Steam アカウントで購入済みの [『活俠傳』](https://store.steampowered.com/app/1859910/Legend_of_Mortal/)；
- 十分な空きディスク容量（ラッパー、Steam、ゲーム本体、バックアップ用）。

Sikarugir Creator を使用して独立したラッパー（例：`SteamWin.app`）を作成します。ラッパー専用の Wine prefix 内で以下の手順を順番に実行します：

1. Wine prefix を初期化し、`Program Files` と `Program Files (x86)` の両ディレクトリが存在することを確認します。
2. Winetricks から `cjkfonts` をインストールします。
3. レジストリ設定 `hidewineexports=enable` を適用します。
4. Windows 版 Steam をインストールします。
5. 起動ターゲットを `C:\Program Files (x86)\Steam\steam.exe` に設定します。
6. Steam にログインし、AppID `1859910` をダウンロード・インストールします。

macOS ネイティブ版 Steam と Windows 版 Steam は共存可能です。ログインや通信に問題が生じた場合は、同一アカウントでのセッション競合を防ぐため、もう一方のクライアントを完全に終了してください。

### ゲームのバイナリアーキテクチャを確認する

Steam ストアページの要件表示にかかわらず、実際のバイナリアーキテクチャを確認します。macOS のターミナルで以下のコマンドを実行します（コマンド内の `/path/to/...` はプレースホルダーです。ご使用の Mac 上の実パスに置き換えてください）：

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

検証済みビルド（Build）での確認結果：

```text
PE32 executable (GUI) Intel 80386, for MS Windows
```

確認結果は PE32（32bit x86）です。この旧版構成では、ネイティブの起動 DLL と描画モジュールを `Mortal.exe` の 32bit 構成に合わせます。マネージド Mod プラグインは、ビルド設定や依存関係、Unity との互換性によって両方のビット数に対応できる場合があります。以降は該当する症状の手順を参照してください。

<a id="graphics"></a>

## 2. D3D11グラフィック初期化エラーを修復する

### 症状と標準の有効化手順

典型的な症状：Steam 上で一瞬「実行中」と表示された直後にゲームが終了する。エラーダイアログや `Player.log` に以下のログが記録されます：

```text
Failed to initialize graphics.
InitializeEngineGraphics failed
d3d11: failed to create device and context (80004005)
```

標準の有効化手順：
1. ラッパーの設定画面を開きます。
2. グラフィック設定で DXMT スイッチを有効にします。
3. ゲームを起動してタイトル画面が表示されるか確認します。

### 発展手順：Engine DLL 手動置換フォールバック

UI 上で DXMT を有効にしても初期化エラーが解消されない場合、ログから DXMT が実際に読み込まれているかを調査します。DXMT モジュールの読み込みに失敗していることを確認できた場合に限り、この Engine レベルの置換フォールバックを実施します。

置換手順：
1. `WINEDEBUG=+loaddll` ログを確認し、現在有効な Engine の実モジュール検索パスを特定します。
2. 元の 32 ビット WineD3D モジュールをバックアップし、置換前ファイルの SHA-256 ハッシュ値を記録します。
3. 対象バージョンの DXMT モジュール（`d3d10core.dll`、`d3d11.dll`、`dxgi.dll`、`winemetal.dll`）を、実際に有効な `i386-windows` ディレクトリへ配置します。
4. 一致する `winemetal.so` を対応する Unix モジュールディレクトリへ配置します。
5. 置換後の各ファイルの SHA-256 ハッシュ値を記録し、バージョンの一致を確認します。

<details markdown="1">
<summary>グラフィックバックエンドの比較と成功ログ</summary>

検証済みビルドにおける各レンダリングパスの検証結果：
- Unity OpenGL：ゲームビルドに対象グラフィックデバイスのサポートが含まれていません。
- WineD3D + MoltenVK：Apple GPU は認識されますが、Direct3D 機能レベルのネゴシエーションに失敗します。
- D3DMetal：主に 64 ビットの D3D11/12 を対象としており、32 ビットゲームには適合しません。
- DXMT：完全な 32 ビット D3D10/11 モジュールを提供し、本 32 ビット（PE32）ゲームに適合します。

モジュール読み込み成功ログの例：

```text
Loaded C:\windows\system32\winemetal.dll
Loaded C:\windows\system32\DXGI.DLL
Loaded C:\windows\system32\d3d11.dll
```

Unity 初期化成功ログの例：

```text
Direct3D:
    Version:  Direct3D 11.0 [level 11.1]
    Renderer: Apple <GPU>
Begin MonoManager ReloadAssembly
```

</details>

日常的な起動には、Steam AppID コマンドライン引数の使用を推奨します：

```text
steam.exe -applaunch 1859910
```

<a id="retina"></a>

## 3. Retinaと解像度の設定

Wine Retina モードに対応するレジストリパス：

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

Retina レンダリングと Unity UI スケーリングは互いに独立した仕組みです。『活俠傳』の Unity UI ロジックは Windows の DPI 設定を基本的に無視します。高解像度では精細な描画が得られますが UI が小さくなり、低解像度では UI が大きく表示されますが引き伸ばしによるぼやけが生じます。

ゲーム側にユーザーが選択したウィンドウ解像度を記憶させる設定を推奨します。検証環境では `1920×1200` を採用し、デスクトップショートカットの起動引数から強制的な `-screen-width` および `-screen-height` を削除しました。

<a id="fonts"></a>

## 4. ショップの価格および合計金額が空白になる問題の修復

### 症状と修復手順

典型的な症状：ゲーム内の会話テキスト、通常数値、銅銭アイコンは表示されますが、ショップ画面のアイテム単価と合計金額のみが空白で表示されません。

修復手順：
1. Windows 版 Steam を完全に終了します。
2. 以下の 4 つのファイル・ディレクトリをバックアップします：
   - `drive_c/windows/Fonts`
   - `system.reg`
   - `user.reg`
   - `userdef.reg`
3. Winetricks を開き、次を選択してインストールします：
```text
fonts → allfonts
```
4. 現在のラッパーを終了して再起動し、専用の wineserver セッションを安全に再起動します。
5. ゲームを起動してショップの金額表示を確認します。

<details markdown="1">
<summary>フォント欠落の要因と検証時の観測ログ</summary>

リソース調査により、`MoneyValue` および `MoneyText` UI コンポーネントには内蔵フォント `SourceHanSerifTC-Bold` が割り当てられており、デフォルト値に `50` が含まれ、数字文字 `0–9` もフォントアトラスに含まれていることが確認されました。原因は Wine prefix 内のフォントセットおよびシステムフォントのマッピング不足です。

初期作成時の prefix に含まれるフォント：

```text
sourcehansans.ttc
unifont.ttf
```

実機検証では `allfonts` の導入により、フォントディレクトリ内のファイル数は 2 個から 121 個（約 284 MB）に増加し、Arial、Tahoma、Calibri、Meiryo、WenQuanYi などのレジストリエントリが書き込まれました。このファイル数と容量は実測時の記録値であり、環境によって差異が生じる場合があります。

各種フォントには独自の利用規約が存在します。フォントは Winetricks 経由で配布元から直接導入し、公開リポジトリや配布用ラッパーにはフォントファイルを含めない方針を維持してください。

</details>

<a id="mods"></a>

## 5. DoorstopとBepInEx Modの読み込みを修復する

詳細な事例報告は、ケーススタディ：[ケース：Wine 10 / x86版『活俠傳』で日本語化Modを読み込む](cases/japanese-mod.ja.md) を参照してください。

### Mod 読み込みの流れとアーキテクチャ整合性

Mod フレームワークは以下の 3 段階で起動します：
1. **Doorstop による介入**：ダミーの `winhttp.dll` がゲーム起動直後に介入し、Preloader を呼び出します。
2. **Preloader による準備**：Unity 基礎アセンブリ（corlibs）を読み込み、ランタイム環境を整えます。
3. **Chainloader による起動**：チェーンローダーが初期化された後、`BepInEx/plugins/` 配下の各 Mod プラグインを読み込みます。

アーキテクチャの適合規則：ネイティブエントリである `winhttp.dll` は、歴史的検証ビルドの 32 ビット（PE32）実行ファイルと厳密に一致させる必要があります。プラグインディレクトリ内のマネージド DLL（C# コンパイルアセンブリ）はアーキテクチャ中立にできる場合がありますが、各プラグインが定める Unity バージョン適合要件に従う必要があります。

### Mod 導入前のバックアップと検証手順

導入するアーカイブごとに以下の確認を行います：
1. アーカイブ内のパスを確認し、絶対パスや `..` によるパストラバーサルリスクを排除します。
2. `winhttp.dll` を含むネイティブ DLL が x86（32 ビット）アーキテクチャであることを確認します。
3. 上書き対象となる既存ファイルのリストを作成します。
4. すべての同名ファイルをタイムスタンプ付きのバックアップディレクトリへ退避します。
5. 展開およびマージ後に各ファイルの SHA-256 ハッシュ値を照合します。
6. ゲームを起動し、`LogOutput.log` の更新時刻が今回の起動時刻と一致していることを確認します（過去ログの誤認を防ぎます）。

### ステップ1：Doorstop をロードする

`winecfg → Libraries` を開き、ゲーム実行ファイル向けに設定を追加します：

```text
winhttp = native,builtin
```

`Mortal.exe` のみに適用されるアプリケーションレベルの DLL override を推奨します。ゲーム実行時、プロセス内に配置した `winhttp.dll` と BepInEx Preloader がロードされていることを確認します。

### ステップ2：Unity バージョンに一致する完全な corlibs を配置する

ゲーム同梱の `Mortal_Data/Managed/mscorlib.dll` はサイズが `3,906,048` バイトにストリップ（裁剪）されています。これに対し、Unity `2020.3.49f1` に適合する完全な未ストリップ版（unstripped corlib）は `4,065,792` バイトです。

正規の手順で入手した完全な corlibs を以下に配置します：

```text
BepInEx/unstripped_corlib/
```

`doorstop_config.ini` を編集します：

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

corlibs は Unity エンジンのバージョンと厳密に一致させ、Unity の利用規約に従って取り扱ってください。公開リポジトリおよび Mod 配布物には corlibs を含めない構成を維持します。

### ステップ3：Wine 修正パッチを含む BepInEx 6 を導入する

作業前に既存の `BepInEx/core` を完全にバックアップします。PR #1254 の修正パッチを含む x86 Mono ビルド `6.0.0-be.785` でコアファイルを置き換えます。

ロード成功時のログ特徴：

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

ログに `Chainloader initialized` が記録されればフレームワークの初期化は成功です。続いて各プラグインの読み込みログが出力されます。検証済み歴史構成では、DiceMaster も同様に `winhttp` override の未設定、corlibs ストリップ、BepInEx 初期化例外の影響を受けていましたが、本手順と同じ Doorstop / corlibs / BepInEx Wine 修復パスを経由することで正常に読み込まれることを確認しています（この結果は検証済みの特定ビルドの組み合わせに限定され、すべての機能や将来バージョンでの動作を保証するものではありません）。

<details markdown="1">
<summary>BepInEx の例外ログと修正パッチの詳細</summary>

旧バージョンの BepInEx 6 は Wine 32 ビット環境下で以下の例外を発生させることがあります：

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

この問題は [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201) で報告され、[PR #1254](https://github.com/BepInEx/BepInEx/pull/1254) にて修正されています。

</details>

<a id="focus"></a>

## 6. 既知の問題

### ウィンドウ切り替え後にタイトルバーをクリックして操作を復帰する

症状：検証環境において、ゲームから他の macOS アプリへ切り替えた後に『活俠傳』へ復帰すると、画面描画は更新されるものの、キーボード・マウス・コントローラーの入力がゲーム内で反応しない場合があります。

実機で確認された有効な復帰操作：
1. 『活俠傳』の `Mortal` ウィンドウへ切り替えて戻ります。
2. ウィンドウ上部の macOS タイトルバー（下図の赤矢印が示す暗色領域）を 1 回クリックします。
3. ゲーム画面へ戻り、操作を再開します。

![Mortalウィンドウのタイトルバーをクリックしてゲーム入力を復帰させる](assets/window-titlebar-focus-recovery.png)

Steam の全体 Overlay および『活俠傳』の個別 Overlay を無効化することで発生頻度を低減できます。タイトルバーのクリックは現時点で高確度な即時復帰策です。根本原因は調査中ですが、Wine、Unity、macOS 間におけるウィンドウフォーカス伝達の不具合に起因する挙動と見られます。

| ゲームバージョン | 発生条件 | 結果 | 証拠 | 確信度 |
| --- | --- | --- | --- | --- |
| Build `20337760` / `release_1.0.5000.13` | 別のmacOSアプリからWineのゲームウィンドウへ戻る | `Mortal`のタイトルバーをクリックすると操作が復帰 | 実機での再現とスクリーンショット | 高 |

<a id="daily"></a>

## 7. 日常の運用・メンテナンス

- Steam の全体設定および『活俠傳』個別設定の「ゲーム内オーバーレイ（Overlay）」を無効化し、アプリ切り替え時の入力ロックの発生確率を低減します。
- プレイ中は `caffeinate` コマンドを活用してスリープを抑止します。ディスプレイスリープ、画面ロック、外部モニタの接続変更が生じた場合は、ゲームを保存した上で、ゲーム、Windows 版 Steam、ラッパーセッションを再起動することを推奨します。
- ゲームと Steam を終了する際は、ゲーム内でセーブを完了した後に、Windows 版 Steam メニューの `Steam → Exit` から安全に終了してください。macOS Dock の Wine アイコンはウィンドウプロキシです。
- Wine を再起動するときは、先にセーブしてゲームを終了し、本ゲームのラッパーだけを対象にします。
- Windows 版 Steam を長時間バックグラウンド待機させた場合、`-applaunch` コマンドに応答しなくなることがあります。Steam の `gameprocess_log.txt` に記録が進まない場合は、該当ラッパー内の Steam および Wine セッションを再起動してください。

<a id="diagnostics"></a>

## 8. リポジトリ同梱の読み取り専用診断スクリプトを使用する

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

このスクリプトは、ラッパーの設定、バイナリアーキテクチャ、Steam マニフェストファイル、レジストリ設定、フォント数、DXMT モジュールのハッシュ値、BepInEx ログ、実行中プロセスを読み取り専用で検査します（コマンド内の `/path/to/SteamWin.app` はプレースホルダーです。ご使用のラッパーの実パスに置き換えてください）。本スクリプトは Wine、Steam、ゲームプロセスを勝手に起動・終了することはなく、ファイルの内容を変更することもありません。

## 参考リンク

- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)
- [DXMT](https://github.com/3Shain/dxmt)
- [BepInEx Wine修正パッチ](https://github.com/BepInEx/BepInEx/pull/1254)
- [『活俠傳』日本語化Mod](https://dlaqe2334.github.io/LOM-JPMOD/)
