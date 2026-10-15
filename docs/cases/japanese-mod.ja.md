# ケース：Wine 10 / x86版『活俠傳』で日本語化Modを読み込む

[日本語ガイドへ戻る](../guide.ja.md) · [简体中文](japanese-mod.zhs.md) · [한국어](japanese-mod.ko.md)

> 本文は 2026-08-29、Build `20337760` の旧版で確認した手順です。32bit コンポーネントの選択はこの構成に対応します。ゲーム 1.06（Build `25953419`）の 64bit 起動入口の修復は [1.06 更新事例](game-1.06.ja.md)を参照してください。各機能の確認状況も記載しています。日本語化 Mod v2.5（64bit 版）の Mac での導入は [v2.5 のページ](japanese-mod-v2.5.ja.md)を参照してください。

本書は、macOS Wine 環境下で日本語化 Mod v2.4 を導入した際の実機検証事例に基づき、障害の特定から 3 段階の修復、動作確認、ロールバック保護までの実践手順を解説します。

## 主要用語の解説

| 用語 | 概要 |
| --- | --- |
| Doorstop | 起動エントリ注入ツール。偽装した `winhttp.dll` を介してゲーム起動時に割り込み、Preloader を呼び出します。 |
| corlibs | Unity Mono ランタイムの基礎クラスライブラリ。不要なコードが削られたストリップ版と完全な未ストリップ版（unstripped）があります。 |
| BepInEx | Unity ゲーム向けの汎用 Mod プラグイン読み込み・管理フレームワーク。 |
| Preloader | BepInEx の先行ローダー。ゲーム本体の処理が始まる前に実行環境を整え、必要な依存関係を準備します。 |
| Chainloader | BepInEx のチェーンローダー。`BepInEx/plugins/` 配下の各 Mod プラグインを順次読み込みます。 |

## 検証条件

| 項目 | 条件 |
| --- | --- |
| ゲーム | Steam AppID `1859910`、Build ID `20337760` |
| Unity | `2020.3.49f1` |
| プロセスアーキテクチャ | `Mortal.exe`、PE32 / x86 |
| Wine | Sikarugir Wine `10.0` |
| Mod | [日本語化Mod v2.4](https://dlaqe2334.github.io/LOM-JPMOD/) |
| 以前の BepInEx | `6.0.0-be.692` |
| 動作確認済みバージョン | `6.0.0-be.785` x86 Mono |
| 検証日 | 2026-08-29 |

## 1. 発生した問題とアーカイブの安全性確認

日本語化 Mod v2.4 をゲームディレクトリへ展開した直後は、ゲーム自体は起動するものの日本語翻訳がまったく反映されませんでした。ログを確認したところ、処理が Chainloader の初期化前に停止していました。

導入および調査の前に、Mod アーカイブの安全確認を実施しました：
1. ZIP アーカイブの完全性を検証し、ファイル破損を排除します。
2. アーカイブ内のパスを確認し、絶対パスや `..` によるパストラバーサルリスクを排除します。
3. アーカイブ内のネイティブ DLL が 32 ビット（x86）アーキテクチャであることを確認します。
4. 上書き対象となる既存ファイルをタイムスタンプ付きの独立ディレクトリへ退避します。
5. 展開およびマージ後にファイルのハッシュ値を照合し、既存の DiceMaster DLL や設定ファイルが保持されていることを確認します。

## 2. 3段階の修復手順と要因の分析

### ステップ1：Doorstop をロードする（エントリ未割り込み問題の解決）

要因分析：Wine は既定で内部組み込みの `winhttp.dll` を優先するため、ゲームディレクトリに配置した Mod 起動用 `winhttp.dll` が読み込まれません。

対応手順：`winecfg` のライブラリ（Libraries）設定を開き、`Mortal.exe` 向けにアプリケーション固有の DLL override を追加します：

```text
winhttp = native,builtin
```

動作結果：プロセスにローカルの `winhttp.dll` が読み込まれ、Preloader が呼び出されるようになりました。ただし、処理は引き続き Chainloader 前で停止しており、次の障害要因の存在が判明しました。

### ステップ2：Unity バージョンに適合する完全な corlibs を配置する（基礎ライブラリ不足の解決）

要因分析：ゲーム同梱の Mono ライブラリはストリップ版であり、BepInEx の初期化に必要な完全な API シグネチャが不足していました。

```text
ゲーム同梱 mscorlib.dll       3,906,048 bytes
Unity 2020.3.49 完全版        4,065,792 bytes
```

対応手順：Unity `2020.3.49f1` に適合する完全な未ストリップ版 corlibs を正規の手順で入手し、`BepInEx/unstripped_corlib/` に配置した上で `doorstop_config.ini` の検索パスを指定します：

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

動作結果：Preloader が正常に実行され、ログに `Done` が記録されました。corlibs は Unity エンジンのバージョンと厳密に一致させ、Unity のソフトウェア利用規約に従って使用します。

### ステップ3：Wine 修正を含む BepInEx 6 へ更新する（プラットフォーム判定例外の解決）

要因分析：旧バージョンの BepInEx `6.0.0-be.692` は、Wine 32 ビット環境下でプラットフォーム補助クラスを初期化する際に例外を発生させました：

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

この問題は [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201) で報告され、[PR #1254](https://github.com/BepInEx/BepInEx/pull/1254) にて修正されています。

対応手順：既存の `BepInEx/core` を完全にバックアップした上で、修正パッチを含む x86 Mono ビルド `6.0.0-be.785` へ差し替えます。エントリポイントは既定の `Application::.cctor` を維持します。

## 3. 検証成功とプラグインの動作確認

上記 3 つの修復を完了してゲームを起動した結果、Mod フレームワークと各プラグインが正常に読み込まれました。

フレームワーク初期化完了ログ：

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

読み込まれたプラグイン一覧：

```text
plugin by Binarizer 1.0.0
DiceMaster 1.0.0
LOM JP Font Patch 0.2.44
LOM JP Ruby Prototype 0.15.113
LOM JP String Vault 0.1.0
```

実行検証の結果：
- Chainloader が 5 個のプラグインをすべて正常に読み込みました。
- ログ出力により 72,977 行の日本語テキスト注入を確認しました。
- ログに新たな Error や Fatal レベルの例外は発生しませんでした。
- ゲーム内言語設定を「簡体字中国語」に指定することで日本語字幕が表示されます。
- ゲーム中に `F5` キーで名前のルビ表示切替、`F7` キーで表示モードの切替が可能です。
- 本検証環境では、DiceMaster 模组も同様に winhttp override 未設定、corlibs ストリップ、BepInEx 初期化例外の影響を受けていましたが、同一の修復パスを経由することで正常に読み込まれることを確認しました。

### 歴史的環境での実測まとめ

| 検証項目 | 検証構成と条件 | 結果 | 証拠と記録 | 確信度 |
| --- | --- | --- | --- | --- |
| 日本語化Mod v2.4 読み込み | Build `20337760`、Wine `10.0`、x86 PE32 | 5 個のプラグインがすべて正常にロード | BepInEx ログで Chainloader initialized および 72,977 行テキスト注入を確認 | 高 |
| DiceMaster 読み込み | 同上環境・同一修復フロー | プラグインが正常にロード・初期化 | ログに `DiceMaster 1.0.0` 出力・異常終了なし | 高 |

## 4. ロールバックと安全境界

安全に元の状態へ復帰できるよう、3 段階のバックアップを保持します：
1. **Mod 導入前のバックアップ**：クリーンなゲームディレクトリを保持；
2. **corlibs 設定前のバックアップ**：元の `doorstop_config.ini` を保持；
3. **be.785 適用前のバックアップ**：元の `BepInEx/core` ディレクトリを保持。

ロールバックの実施要件：ファイルを復元する前に、必ずゲーム内でセーブを完了した上で、ゲーム、Windows 版 Steam、およびラッパーの wineserver プロセスを完全に終了してください。復元の際は同一段階のファイルを一式で差し戻し、異なる BepInEx ビルドの core DLL を混在させないようにしてください。
