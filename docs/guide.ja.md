---
layout: page
title: "Apple Silicon Macで『活俠傳』を動かす：インストール・フォント・Mod修復"
permalink: /docs/guide.ja/
---

[ホーム](../README.md) · [简体中文](guide.zhs.md) · [繁體中文](guide.zht.md) · [한국어](guide.ko.md)

> **本書はゲーム 1.06（Build `25953419`、64bit）に対応しています。** 2026 年 10 月 15 日に手元の環境で確認しました。
> - **日本語化 Mod v2.5 を入れる・1.05 から更新したら日本語にならなくなった**：[日本語化 Mod を使っている場合](#upgrade-jp)へ。v2.5 を入れたあと Mac では 2 か所の修正が必要です。
> - まだ 1.05（Build `20337760`、32bit）を使っている場合：末尾の [1.05 の旧構成](#legacy)をご覧ください。
{: .callout}

本書は、Apple Silicon Mac で自分で購入した正規版『活俠傳』を遊びたい方に向けたガイドです。Sikarugir、Wine、Windows 版 Steam を使ってゲームを導入し、グラフィック初期化エラー、ショップの文字が表示されない問題、Mod が読み込まれない問題など、よくあるトラブルへの対処法をまとめています。

* 目次
{:toc}

## 検証済み環境

| 項目 | 検証済み構成 |
| --- | --- |
| ゲーム | Steam AppID `1859910`、Build `25953419`、1.06 |
| Unity | `2020.3.49f1` |
| 実行ファイル | `Mortal.exe`、`UnityPlayer.dll`、PE32+ / x64 |
| ラッパー実行コンポーネント | Sikarugir Creator `1.0.2`、Template `1.0.22` |
| Wine | Sikarugir Wine `10.0 revision 8` |
| グラフィックバックエンド | テンプレート同梱の DXMT `v0.80-244-g7c8dee1`、D3D11 → Metal |
| Mod の入口 | Doorstop `4.4.0` Windows x64（`winhttp.dll`） |
| Mod フレームワーク | BepInEx `6.0.0-be.785` Unity.Mono マネージドコア |
| 検証日 | 2026-10-15 |

この環境は、1.05 の時期に作った Wine prefix をそのままアップグレードしたものです。フォント、レジストリ、DLL override も当時の設定を引き継いでいます。Wine、Steam、macOS、ゲーム本体のアップデートは、いずれも結果に影響する可能性があります。設定を変更する前に、バージョン番号を記録し、日時付きのバックアップを作成してください。

## 症状別の対処早見表

該当する症状が出たときだけ、対応するセクションを実施してください。ゲームが問題なく動いているなら、追加の修復は必要ありません。

| 症状または目的 | 該当セクション |
| --- | --- |
| 初めてインストールする | [1. Windows 版 Steam のラッパーを作成する](#install) |
| 1.06 に更新したら Mod がすべて効かなくなった | [1.05 から 1.06 へのアップグレード](#upgrade) |
| 起動直後に強制終了する / D3D11 エラー | [2. D3D11 グラフィック初期化エラーを修復する](#graphics) |
| 画面がぼやける、または UI が小さすぎる | [3. Retina と解像度](#retina) |
| ショップの単価と合計金額が空白になる | [4. ショップの価格表示が空白になる問題を修復する](#fonts) |
| Mod が反応しない / エラーが出る | [5. BepInEx Mod の導入と修復](#mods) |
| 日本語化 Mod を入れたい | [6. 日本語化 Mod v2.5](#jpmod) |
| ウィンドウを切り替えるとキーボードやマウスが効かなくなる | [7. 既知の問題](#focus) |
| 長時間の放置やスリープからの復帰 | [8. 日常の運用のヒント](#daily) |
| 現在の環境を調べたい | [9. 読み取り専用の診断スクリプト](#diagnostics) |

## 主要用語

| 用語 | 簡単な説明 |
| --- | --- |
| ラッパー（Wrapper） | macOS 上の `.app` アプリケーションバンドル。中に Wine と Windows アプリが入っています。 |
| Wine / Wine prefix | Wine は Windows アプリを macOS 上で動かすための仕組みです。prefix はラッパーの中に作られる仮想の Windows 環境（仮想 C ドライブとレジストリ）のことです。 |
| Winetricks | Wine prefix に Windows のランタイムやフォントを導入するための補助ツール。 |
| DXMT | Direct3D 11 の描画命令を Apple の Metal 向けに変換するレイヤー。 |
| BepInEx | Unity 製ゲームでよく使われる Mod の読み込みフレームワーク。 |
| Doorstop | Mod の入口となるツール。`winhttp.dll` に成りすましてゲーム起動時に読み込まれ、BepInEx をゲームに引き込みます。 |
| ネイティブ DLL / マネージド DLL | ネイティブ DLL（`winhttp.dll` など）はゲームと同じ 64bit でなければなりません。マネージド DLL（C# で書かれた BepInEx や Mod プラグイン）は、多くの場合ビット数を問いません。 |

<a id="install"></a>

## 1. Windows 版 Steam のラッパーを作成する

事前準備：

- Apple Silicon Mac、macOS 14 以降、Rosetta 2 導入済み。
- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)（Creator と Template は最新版を推奨。手元では Creator `1.0.2` / Template `1.0.22` で検証しました）。
- 個人の Steam アカウントで購入済みの [『活俠傳』](https://store.steampowered.com/app/1859910/Legend_of_Mortal/)。
- 十分な空きディスク容量（ラッパー、Steam、ゲーム本体で約 12 GB。バックアップ用の容量も別途必要です）。

Sikarugir Creator で独立したラッパー（例：`SteamWin.app`）を作成し、そのラッパー専用の Wine prefix で次の手順を順番に実施します。

1. prefix を初期化し、`Program Files` と `Program Files (x86)` の両方があることを確認します。
2. Winetricks で `cjkfonts` をインストールします。
3. レジストリに `hidewineexports=enable` を設定します。
4. Windows 版 Steam をインストールし、起動ターゲットを `C:\Program Files (x86)\Steam\steam.exe` に設定します。
5. Steam にログインし、AppID `1859910` をダウンロードします。

macOS ネイティブ版 Steam と Windows 版 Steam は共存できます。ログインや通信がおかしいときは、同じアカウントのセッションが互いに追い出し合わないよう、もう一方のクライアントを完全に終了してください。

### ゲームが 64bit であることを確認する

macOS のターミナルで次のコマンドを実行します（`/path/to/LegendOfMortal` は実際のゲームフォルダのパスに置き換えてください）。

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

1.06 での結果：

```text
PE32+ executable (GUI) x86-64, for MS Windows
```

`PE32+` / `x86-64` は 64bit を意味します。以降のすべての**ネイティブ**コンポーネント（`winhttp.dll`、DXMT モジュール）は 64bit 版を選んでください。`PE32` / `Intel 80386` と表示された場合は、まだ 1.05 のままです。[1.05 の旧構成](#legacy)をご覧ください。

<a id="upgrade"></a>

## 1.05 から 1.06 へのアップグレード

1.06 では `Mortal.exe` と `UnityPlayer.dll` が 32bit から 64bit に変わりました。旧版のガイドで入れた Mod の入口 `winhttp.dll` は 32bit のままなので、64bit のゲームはこれを読み飛ばします。その結果、**ゲームは起動するのに、日本語化 Mod を含むすべての Mod が同時に効かなくなります**。

<a id="upgrade-jp"></a>

### 日本語化 Mod を使っている場合（ほとんどの方はこちら）

日本語化 Mod v2.5 は 64bit 版の入口を同梱しているので、**v2.5 を README どおり入れてから、Mac 用に 2 か所直す**のがいちばん簡単です。

> v2.5 を「すべて上書き」したあと、Mac では次の 2 つを必ず行ってください。やらないと日本語にならず、ほかの Mod も全部止まります。
> 1. `BepInEx/core` を上書き前のもの（**be.785**）に戻す
> 2. `doorstop_config.ini` を `dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"` に直す
{: .callout .warn}

1. **セーブして終了する**：ゲーム内でセーブして終了し、Windows 版 Steam も `Steam → Exit` で終了します。
2. **バックアップする**：ゲームフォルダの `winhttp.dll`、`doorstop_config.ini`、`BepInEx` フォルダ全体を日時付きのフォルダにコピーします。**この `BepInEx/core`（be.785）を手順 4 で使います。** セーブデータ（`drive_c/users/<ユーザー名>/AppData/LocalLow/Obb Studio/Mortal`）も別にコピーしておきます。
3. **v2.5 を入れる**：配布 ZIP を **Finder で展開**し（`unzip` は日本語のファイル名で失敗します）、中身をすべてゲームフォルダに上書きコピーします。
4. **コアを戻す**：ゲームフォルダの `BepInEx/core` を削除し、手順 2 のバックアップの `BepInEx/core` を戻します。
5. **ini を直す**：`doorstop_config.ini` の `dll_search_path_override` の行を上の囲みのとおりに書き換えます。
6. **起動して確認する**：今回の起動で更新された `BepInEx/LogOutput.log` に、`BepInEx 6.0.0-be.785`、`Process bitness: 64-bit (x64)`、`Loading [LOM JP Font Patch …]`、`Chainloader startup complete` があれば成功です。ゲーム画面が日本語になっていることも確かめます。

`winhttp.dll` は v2.5 同梱の 64bit 版のままで問題ありません。手元の環境では、この手順で日本語化 Mod・DiceMaster・セーブ拡張の 8 プラグインがすべて読み込まれ、エラーは出ませんでした。

**ゲーム内の「更新を確認」で Mod を更新したあと**も、念のため `BepInEx/core` が be.785 のままか、`doorstop_config.ini` に `unstripped_corlib` が残っているかを確認してください。くわしい手順、失敗したときの症状、検証記録は **[日本語化 Mod v2.5 を Mac で導入する](cases/japanese-mod-v2.5.ja.md)** にまとめています。

<a id="upgrade-dll"></a>

### 日本語化 Mod を使わない場合：`winhttp.dll` だけを交換する

> 実際に交換するのは `winhttp.dll` だけです。`doorstop_config.ini`、`BepInEx/unstripped_corlib`、`BepInEx/core`（be.785）、DiceMaster やセーブ拡張などのマネージドプラグインは、**すべてそのまま残してください**。ゲームが 64bit になったからといって、BepInEx 一式を入れ替えてはいけません。
{: .callout}

1. **セーブして終了する**：ゲーム内でセーブして終了し、そのあと Windows 版 Steam のメニュー `Steam → Exit` で Steam も終了します。
2. **バックアップする**：ゲームフォルダの `winhttp.dll`、`doorstop_config.ini`、`BepInEx` フォルダ全体を、日時付きのフォルダにコピーします。あわせてセーブデータ（`drive_c/users/<ユーザー名>/AppData/LocalLow/Obb Studio/Mortal`）も別にコピーしておきます。
3. **ビット数を確認する**：
   ```bash
   file "/path/to/LegendOfMortal/Mortal.exe"
   file "/path/to/LegendOfMortal/winhttp.dll"
   ```
   前者が `PE32+ … x86-64`、後者が `PE32 … Intel 80386` なら、この問題に該当します。
4. **x64 版 Doorstop に差し替える**：[UnityDoorstop 4.4.0 のリリースページ](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0)から Windows 版をダウンロードし、その中の **x64** フォルダにある `winhttp.dll` で、ゲームフォルダ直下の同名ファイルを上書きします。
5. **DLL override が残っていることを確認する**：ラッパーの `winecfg` で、Applications タブから `Mortal.exe` を選び、Libraries タブに `winhttp = native,builtin` があることを確認します。
6. **起動して今回のログを確認する**：`BepInEx/LogOutput.log` を開き、まず更新時刻が今回の起動より後であることを確認します（古いログだと判断を誤ります）。そのうえで、次の内容が含まれていることを確認します。
   ```text
   Process bitness: 64-bit (x64)
   Chainloader initialized
   Chainloader startup complete
   ```
7. **ゲーム内で実際に機能を確認する**：ログに `Loading [プラグイン名]` と出ても、読み込みが始まったことしか分かりません。機能が使えるかどうかは、ゲーム内で確認してください。

手元の環境でこの手順どおりに修復したところ、DiceMaster `1.0.0` とセーブ拡張 `1.2.0` はどちらも読み込まれるようになりました。セーブ拡張は動作を確認済みで、DiceMaster の選択肢の収益表示も表示されることを確認しました。DiceMaster の数値の正確さ、新しいストーリーの解析、サイコロの制御は、まだ検証していません。

**任意：実行コンポーネントも同時にアップグレードする。** 手元の環境では、同じ日にラッパーを Template `1.0.11` / Wine `10.0` から Template `1.0.22` / Wine `10.0 revision 8` へアップグレードしました。これは Mod の入口の修復とは関係がないため、別々に実施し、別々にバックアップを取ることをおすすめします。そうすれば、問題が起きたときにどの作業が原因か判断しやすくなります。Wine `11.0 revision 1` は、手元の環境では `wineboot` の初期化で止まってしまったため、今のところおすすめしません。

詳しい調査の経緯、検証範囲、元に戻す方法は [1.06 更新事例](cases/game-1.06.ja.md)をご覧ください。

<a id="graphics"></a>

## 2. D3D11 グラフィック初期化エラーを修復する

典型的な症状：Steam に「実行中」と表示された直後にゲームが終了する、または `Player.log` に次のログが出る。

```text
Failed to initialize graphics.
d3d11: failed to create device and context (80004005)
```

1. ラッパーの設定を開き、グラフィック設定で DXMT を有効にします。
2. ゲームを起動し、メインメニューまで進めることを確認します。

有効にしてもエラーが出る場合は、まず `WINEDEBUG=+loaddll` のログで、DXMT が本当に読み込まれているかを確認します。読み込まれていないと確認できた場合にだけ、Engine 内のモジュールを手動で置き換えます。

1. ログから、実際に使われている Engine のフォルダを確認します。
2. 元の 64bit 版 WineD3D モジュールをバックアップし、SHA-256 を記録します。
3. 対応バージョンの DXMT モジュール（`d3d10core.dll`、`d3d11.dll`、`dxgi.dll`、`winemetal.dll`）を `x86_64-windows` フォルダに置きます。
4. 対応する `winemetal.so` を `x86_64-unix` フォルダに置きます。
5. 置き換えたあとの SHA-256 を記録します。

成功すると、`Player.log` に次のように表示されます。

```text
Direct3D:
    Version:  Direct3D 11.0 [level 11.1]
    Renderer: Apple <GPU>
```

普段の起動には `steam.exe -applaunch 1859910` を使うのがおすすめです。

<a id="retina"></a>

## 3. Retina と解像度

Wine の Retina モードのレジストリ項目：

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

Retina とゲームの UI スケーリングは別のものです。『活俠傳』の UI は、Windows の DPI 設定をほとんど無視します。解像度を上げると画面は鮮明になりますが UI は小さくなり、下げると UI は大きくなりますがぼやけます。ゲームに自分で選んだ解像度を記憶させるのがおすすめです（手元の環境では `1920×1200`）。また、起動引数から強制的な `-screen-width` / `-screen-height` を外してください。

<a id="fonts"></a>

## 4. ショップの価格表示が空白になる問題を修復する

症状：中国語の会話、通常の数値、銅銭アイコンは正常に表示されるのに、ショップの単価と合計金額だけが空白になる。

1. Windows 版 Steam を完全に終了します。
2. `drive_c/windows/Fonts`、`system.reg`、`user.reg`、`userdef.reg` をバックアップします。
3. Winetricks を開き、`fonts → allfonts` をインストールします。
4. ラッパーを再起動し、ゲームを起動してショップの金額が正常に表示されることを確認します。

<details markdown="1">
<summary>原因とテスト記録</summary>

`MoneyValue` / `MoneyText` コンポーネントは内蔵フォント `SourceHanSerifTC-Bold` を使っており、フォントアトラスにも `0–9` が含まれています。問題は、prefix のフォントセットとフォントのマッピングが不完全なことにありました。作成直後の prefix には `sourcehansans.ttc` と `unifont.ttf` しかありませんでしたが、`allfonts` を導入すると 121 ファイル（約 284 MB）に増えました。この数は環境によって異なります。

各フォントには、それぞれ別のライセンスがあります。フォントは Winetricks を使って配布元から導入してください。本リポジトリではフォントを一切配布していません。

</details>

<a id="mods"></a>

## 5. BepInEx Mod の導入と修復

### 読み込みの流れ

1. **Doorstop**：Wine がゲームフォルダの `winhttp.dll` を読み込み、これが BepInEx Preloader を起動します。
2. **Preloader**：Unity の基本ライブラリ（corlibs）を読み込み、環境を整えます。
3. **Chainloader**：`BepInEx/plugins/` 配下の Mod を順番に読み込みます。

この 3 つの段階それぞれに、Wine 上ならではの落とし穴があります。以下の 3 つのステップは、それに対応しています。1.05 の時期に導入済みで、1.06 へアップグレードしただけの方は、[1.05 から 1.06 へのアップグレード](#upgrade)だけをご覧ください。

### 導入前の確認

Mod のアーカイブごとに、次の確認を行ってください。

1. アーカイブ内のパスを確認し、絶対パスや `..` が含まれていないことを確かめます。
2. `file` コマンドで、`winhttp.dll` などのネイティブ DLL が 64bit（`PE32+`）であることを確認します。
3. 上書きされるファイルを一覧にし、先に日時付きのバックアップフォルダへコピーします。
4. 展開したあと、SHA-256 を照合します。
5. 起動後に、`LogOutput.log` が今回の起動で生成されたものであることを確認します。

> 日本語のファイル名を含むアーカイブは、Finder または `ditto -x -k` で展開してください。macOS 標準の `unzip` は、日本語のファイル名のところでエラーになり、中途半端なファイルが残ってしまいます。
{: .callout}

### ステップ1：Wine に Doorstop を読み込ませる

Wine はデフォルトで、自前の `winhttp.dll` を優先して使います。`winecfg` の Applications タブで `Mortal.exe` を選び、Libraries タブで次を追加します。

```text
winhttp = native,builtin
```

ゲームフォルダの `winhttp.dll` は 64bit でなければなりません。手元で検証したのは [UnityDoorstop 4.4.0](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0) の Windows **x64** 版です。

### ステップ2：完全な corlibs を用意する

ゲーム同梱の `Mortal_Data/Managed/mscorlib.dll` は軽量化されたストリップ版（`3,906,048` バイト）で、Unity `2020.3.49f1` の完全版は `4,065,792` バイトです。正規の方法で入手した、バージョンの一致する完全な corlibs を `BepInEx/unstripped_corlib/` に置き、`doorstop_config.ini` を編集します。

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

corlibs は Unity のバージョンと完全に一致している必要があり、Unity のライセンスに従って取り扱ってください。本リポジトリでは corlibs を配布していません。1.06 でもまだ必要かどうかは単独では検証していません。手元で検証した構成では、残したままにしています。

### ステップ3：Wine 向けの修正を含む BepInEx 6 を使う

古い BepInEx 6（`be.692` など）は、Wine 上で次の例外を出すことがあります。

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

この問題は [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201) で報告され、[PR #1254](https://github.com/BepInEx/BepInEx/pull/1254) で修正されています。先に `BepInEx/core` をバックアップしてから、`6.0.0-be.785` の Unity.Mono コアに置き換えてください。

手元の環境で実際に使っているのは、be.785 のマネージドコアと、Doorstop 4.4.0 x64 の `winhttp.dll` です。マネージドコアはビット数を問わないため、1.05 の時期に導入した be.785 は 1.06 でもそのまま使えます。新規にインストールする場合は BepInEx の win-x64 パッケージをそのまま使えますが、中の `winhttp.dll` が 64bit であることを確認してください。

成功すると、ログに次の内容が含まれます。

```text
BepInEx 6.0.0-be.785
Process bitness: 64-bit (x64)
Chainloader initialized
```

<a id="jpmod"></a>

## 6. 日本語化 Mod v2.5

v2.5 は 64bit 版のゲーム向けで、ゲーム内アップデート機能も付きました。Mac では README どおり「すべて上書き」したあとに、`BepInEx/core` を be.785 に戻し、`doorstop_config.ini` に `unstripped_corlib` のパスを足す必要があります（同梱の be.692 は Wine 上で `PlatformHelper.Current` エラーを出して止まるため）。

手順は [1.05 から 1.06 へ：日本語化 Mod を使っている場合](#upgrade-jp)、詳しい説明と検証記録は **[日本語化 Mod v2.5 を Mac で導入する](cases/japanese-mod-v2.5.ja.md)** をご覧ください。

<a id="focus"></a>

## 7. 既知の問題：ウィンドウを切り替えたあと、タイトルバーをクリックする必要がある

他の macOS アプリから『活俠傳』に戻ったあと、画面は正常に更新されるのに、キーボード、マウス、コントローラーが反応しないことがあります。

1. `Mortal` のゲームウィンドウに切り替えます。
2. ウィンドウ上部の濃い色のタイトルバー（下の図の赤い矢印のところ）を 1 回クリックします。
3. ゲームに戻って操作を続けます。

![Mortal ウィンドウのタイトルバーをクリックしてゲーム入力を復帰させる](assets/window-titlebar-focus-recovery.png)

Steam 全体のオーバーレイと、このゲームのオーバーレイを無効にすると、発生する頻度を下げられます。この現象は 1.05 の実機で再現し、対処法も確認しました。1.06 では、まだ改めて確認していません。根本的な原因は調査中ですが、Wine、Unity、macOS の間でフォーカスの受け渡しがうまくいっていないときの特徴に当てはまります。

<a id="daily"></a>

## 8. 日常の運用のヒント

- Steam 全体のオーバーレイと、このゲームのオーバーレイを無効にします。
- プレイ中は `caffeinate` でシステムのスリープを防げます。ノートを閉じてスリープしたとき、画面をロックしたとき、外部ディスプレイを抜き差ししたときは、セーブしてからゲーム、Steam、ラッパーを再起動することをおすすめします。
- 終了するときは、先にゲーム内でセーブし、そのあと Windows 版 Steam の `Steam → Exit` を使います。Dock の Wine アイコンは、ウィンドウの代理にすぎません。
- Windows 版 Steam を長時間バックグラウンドに置いておくと、`-applaunch` に反応しなくなることがあります。`gameprocess_log.txt` に新しい記録が増えないときは、このラッパーの Steam と Wine のセッションを再起動してください。

<a id="diagnostics"></a>

## 9. 読み取り専用の診断スクリプト

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

このスクリプトが読み取るのは、ラッパーの設定、ゲームのアーキテクチャ、Steam のマニフェスト、レジストリ、フォント数、DXMT モジュールのハッシュ値、BepInEx のログ、実行中のプロセスだけです。プロセスを起動も終了もせず、ファイルも変更しません。スクリプトは[プロジェクトのリポジトリ](https://github.com/li-yifei/legend-of-mortal-mac-guide)にあります。

## AI アシスタントに手伝ってもらう

Wine やターミナルに不慣れな方は、本書を AI コーディングアシスタントに渡して、まず読み取り専用で手元の環境を調べてもらい、そのあと症状に合わせて対処してもらうこともできます。その際は、次の点を守ってください。

- Steam へのログインは自分で手動で行い、AI にアカウントのパスワードやトークンを渡さないでください。
- ファイルの置き換えや、リスクのあるコマンドは、先に自分で確認してから実行してください。
- Engine、prefix、ゲームフォルダを変更する前に、日時付きのバックアップを作成してください。

<a id="legacy"></a>

## 1.05 の旧構成

<details markdown="1">
<summary>1.05（Build <code>20337760</code>、32bit）の検証環境と違い</summary>

2026-08-29 に検証：

| 項目 | 構成 |
| --- | --- |
| ゲーム | Build `20337760`、`release_1.0.5000.13` |
| 実行ファイル | `Mortal.exe`、PE32 / x86 |
| ラッパー | Sikarugir Template `1.0.11`、Wine `10.0` |
| グラフィックバックエンド | 32bit DXMT |
| Mod | Doorstop x86 `winhttp.dll`、BepInEx `6.0.0-be.785` x86 Mono |

1.06 との違い：

- `file Mortal.exe` の結果が `PE32 executable (GUI) Intel 80386` になります。
- ネイティブコンポーネントはすべて 32bit を選びます。`winhttp.dll` は x86 版を使い、DXMT を手動で置き換えるときは `i386-windows` / `i386-unix` に置きます。
- D3DMetal は 64bit のみが対象で、1.05 には使えません。DXMT は 32bit の D3D10/11 モジュールを提供しています。
- 日本語化 Mod v2.4 と DiceMaster の読み込みの流れは、[日本語化 Mod v2.4 事例](cases/japanese-mod.ja.md)をご覧ください。

</details>

## 参考資料

- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)
- [DXMT](https://github.com/3Shain/dxmt)
- [UnityDoorstop 4.4.0](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0)
- [BepInEx Wine 修正（PR #1254）](https://github.com/BepInEx/BepInEx/pull/1254)
- [『活俠傳』日本語化 Mod](https://dlaqe2334.github.io/LOM-JPMOD/)
