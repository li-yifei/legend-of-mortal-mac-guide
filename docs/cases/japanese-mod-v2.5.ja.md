# 日本語化 Mod v2.5 を Mac で導入する（ゲーム 1.06）

[日本語ガイドへ戻る](../guide.ja.md) · [1.06 更新事例](game-1.06.ja.md) · [v2.4 の旧事例](japanese-mod.ja.md)

> **結論：日本語化 Mod v2.5 は README どおり「すべて上書き」で入れたあと、Mac では 2 か所だけ直せば動きます。**
> 1. `BepInEx/core` を **be.785** に戻す
> 2. `doorstop_config.ini` に **`BepInEx\unstripped_corlib`** を足す
>
> 2026 年 10 月 15 日、ゲーム 1.06（Build `25953419`）・Wine `10.0 revision 8` で確認しました。

## なぜ Mac では追加作業が必要か

v2.5 は 64bit 版のゲームに対応し、64bit 版 Doorstop（`winhttp.dll`、バージョン表記 `4.3.0`）を同梱しています。この部分は Mac でもそのまま動きました。

問題は同梱の BepInEx コアが **`6.0.0-be.692`** であることです。be.692 は Wine 上で起動直後に次のエラーを出して止まります（1.05 の 32bit 版と同じ不具合で、64bit 版でも再現しました）。

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

この不具合は [BepInEx PR #1254](https://github.com/BepInEx/BepInEx/pull/1254) で修正済みで、修正を含む **be.785** に入れ替えると解消します。また、同梱の `doorstop_config.ini` は `dll_search_path_override = "BepInEx\core"` だけなので、Mac で必要な完全版 corlibs（`BepInEx/unstripped_corlib`）が読み込まれなくなります。

### README どおりに上書きしただけの場合の症状

- ゲームは起動するが、**日本語にならない**。DiceMaster やセーブ拡張など他の Mod も**すべて止まる**。
- `BepInEx/LogOutput.log` が作られない（または古いまま）。
- ゲームフォルダ直下に `preloader_日時.log` ができ、上記の `PlatformHelper.Current` エラーが書かれている。

この状態なら、下の「3. Mac 用の仕上げ」だけ行えば直ります。

## 1. 準備とバックアップ

1. ゲーム内でセーブして終了し、Windows 版 Steam も `Steam → Exit` で終了します。
2. ゲームフォルダ（`Mortal.exe` があるフォルダ）の次のものを、日時付きのフォルダにコピーします。
   - `winhttp.dll`、`doorstop_config.ini`
   - `BepInEx` フォルダ全体（**特に `BepInEx/core` は後で使います**）
3. セーブデータ（`drive_c/users/<ユーザー名>/AppData/LocalLow/Obb Studio/Mortal`）も別にコピーします。

ゲームは 1.06 に更新済みで、Mod の構成だけが 1.05（v2.4・32bit 版 `winhttp.dll`）のままという方も、この手順で大丈夫です。Mod の入口は v2.5 が 64bit 版に入れ替えるので、別途 Doorstop を用意する必要はありません。v2.4 の古いファイルは、v2.5 の LegacyCleanup が起動時に整理する設計になっています（v2.4 からの上書きそのものは、今回は未検証です）。ゲーム本体がまだ 1.05 の場合は、先に Steam でゲームを更新してください。

## 2. v2.5 を README どおりに入れる

1. [配布ページ](https://dlaqe2334.github.io/LOM-JPMOD/)から導入用 ZIP を入手します。Windows 用インストーラーではなく **ZIP** を使ってください。
2. **Finder でダブルクリック**して展開します（ターミナルなら `ditto -x -k LOM_JP_Mod_v2.5.zip 展開先`）。macOS の `unzip` は日本語のファイル名でエラーになり、ファイルが欠けます。
3. 展開したフォルダの中身を、すべてゲームフォルダにコピーして上書きします。

ここまでで `winhttp.dll` は 64bit 版になりますが、`BepInEx/core` は be.692 に、`doorstop_config.ini` は corlibs のパスがない状態になっています。

## 3. Mac 用の仕上げ（2 か所）

### ① BepInEx コアを be.785 に戻す

1. ゲームフォルダの `BepInEx/core` を削除します。
2. 手順 1 でバックアップした `BepInEx/core`（be.785）をそのまま戻します。
   - 手元に be.785 がない場合は、BepInEx の Bleeding Edge ビルドから `6.0.0-be.785` の Unity.Mono 版を入手し、その `BepInEx/core` を使います。
3. 確認したい場合は、ターミナルで次を実行し、`be.785` と表示されることを確かめます。
   ```bash
   strings "/path/to/LegendOfMortal/BepInEx/core/BepInEx.Core.dll" | grep -m1 "6.0.0-be"
   ```

### ② doorstop_config.ini に corlibs のパスを足す

`doorstop_config.ini` をテキストエディットなどで開き、`[UnityMono]` の行を次のように書き換えます。

```ini
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

`BepInEx/unstripped_corlib/` には、Unity `2020.3.49f1` に合った完全版 corlibs が必要です。以前のガイドで用意したものがあれば、そのまま残っています。初めての場合は[日本語ガイドの第 5 章](../guide.ja.md#mods)を参照してください。

### 忘れずに：DLL override

ラッパーの `winecfg` で `Mortal.exe` に `winhttp = native,builtin` が設定されていることを確認します。以前の構成から引き継いだ環境なら、すでに入っています。

`winhttp.dll` は v2.5 同梱の 64bit 版（4.3.0）のままで動作を確認しました。手元にある Doorstop 4.4.0 x64 に置き換える必要はありません。

## 4. 起動して確認する

`BepInEx/LogOutput.log` が**今回の起動時刻に更新されている**ことを確かめてから、次の行があるかを見ます。

```text
BepInEx 6.0.0-be.785
Process bitness: 64-bit (x64)
[LOM JP Legacy Cleanup] selected runtime projected: 2.5.49
Chainloader initialized
Loading [LOM JP Font Patch 0.2.49]
Loading [LOM JP Ruby Prototype 0.15.145]
[LOM JP String Vault] protected Stringtable loaded: 92454 rows
Loading [LOM JP Updater 0.1.0]
Chainloader startup complete
```

手元の環境では、日本語化 Mod の 6 個（plugin by Binarizer、Font Patch、Ruby Prototype、String Vault、Update Menu、Updater）に DiceMaster とセーブ拡張を加えた **8 個のプラグインがすべて読み込まれ**、Error や Exception は出ませんでした。ゲーム画面でも日本語表示を確認しています。

## 5. ゲーム内アップデート（更新を確認）について

v2.5 にはタイトル画面から更新を取得する機能があります。Mac（Wine）上でも GitHub への接続は成功し、検証時点では配布側に新しい版がなかったため「No applicable update」となりました。

アップデーターが更新するのは翻訳データとランタイム（`BepInEx/plugins/LOM_JP`、`BepInEx/cache/lom.jp.updater`）で、パッケージの構成上 `BepInEx/core` は対象外と見られます。ただし実際の更新はまだ試せていないため、**更新したあとは念のため次の 2 点を確認してください**。

- `BepInEx/core` が be.785 のままか（上の `strings` コマンド）
- `doorstop_config.ini` に `BepInEx\unstripped_corlib` が残っているか

もし手動で ZIP を入れ直した場合は、もう一度「3. Mac 用の仕上げ」を行います。

## 6. うまくいかないとき・元に戻すとき

| 症状 | 原因と対処 |
| --- | --- |
| 日本語にならず、`preloader_*.log` に `PlatformHelper.Current` | コアが be.692 のまま。①を行う |
| `LogOutput.log` 自体が更新されない | `winhttp = native,builtin` がない、または `winhttp.dll` が 32bit。`file winhttp.dll` で `PE32+` か確認 |
| Preloader の途中で止まる | `unstripped_corlib` のパスがない、または中身が Unity のバージョンと合わない。②を確認 |
| 一部の文字が出ない・崩れる | Mod 側の表示の問題の可能性。配布ページの不具合報告の案内に従う |

元に戻すときは、ゲームと Steam を終了してから、手順 1 のバックアップを一式で戻します。日本語化 Mod だけを外す場合は、同梱の `README_JP.txt` にある削除リストに従ってください。**DiceMaster などほかの Mod も使っているなら、`BepInEx` フォルダ全体は消さないでください。**

## 検証の記録

| 項目 | 内容 |
| --- | --- |
| ゲーム | Steam AppID `1859910`、Build `25953419`、x64 |
| ラッパー | Sikarugir Template `1.0.22`、Wine `10.0 revision 8`、DXMT |
| Mod | 日本語化 Mod v2.5（runtime `2.5.49`、translation `2026.10.15.354`）、ZIP SHA-256 `16a6de80…1bdf35` |
| 検証 A | README どおり上書きのみ → be.692 が `PlatformHelper.Current` で停止、全 Mod 無効 |
| 検証 B | A のあと be.785 コアと corlibs パスを戻す → 8 プラグイン読み込み、エラーなし、日本語表示をプレイヤーが確認 |
| 未検証 | 実際のゲーム内アップデート適用後の状態、1.06 / DLC2 の全文の翻訳状況、長時間のプレイ |

検証は本番環境を複製したテスト用ラッパーで行い、本番のゲームフォルダとセーブデータに変更がないことをハッシュで確認しました。日本語化 Mod は非公式のファン翻訳です。翻訳内容についての問い合わせは配布元へお願いします。
