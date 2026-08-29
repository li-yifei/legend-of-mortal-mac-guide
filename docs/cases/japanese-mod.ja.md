# ケース：Wine 10 / x86版『活俠傳』で日本語化Modを読み込む

[日本語ガイドへ戻る](../guide.ja.md) · [简体中文](japanese-mod.zh-CN.md) · [한국어](japanese-mod.ko.md)

## 結論

日本語化Mod v2.4のファイルはゲームディレクトリへ正しく配置されていました。プラグイン読み込みはChainloader初期化前で停止していました。最終的に動作した構成は次の通りです。

- `Mortal.exe`限定の`winhttp = native,builtin`。
- Unity `2020.3.49f1`に一致する完全なcorlibs。
- `BepInEx/unstripped_corlib`を優先するDoorstop設定。
- BepInEx Wine修正PR #1254を含むx86 Mono `6.0.0-be.785`。
- BepInEx既定の`Application::.cctor`エントリ。
- ゲーム内言語を簡体字中国語に設定。

修復後、Chainloaderが5プラグインを読み込み、日本語文字列72,977行が注入されました。DiceMasterの長期的な未動作も同じ原因の修復で解消しました。

## 検証条件

| 項目 | 条件 |
| --- | --- |
| ゲーム | AppID `1859910`、Build ID `20337760` |
| Unity | `2020.3.49f1` |
| プロセス | `Mortal.exe`、PE32 / x86 |
| Wine | Sikarugir Wine `10.0` |
| Mod | [日本語化Mod v2.4](https://dlaqe2334.github.io/LOM-JPMOD/) |
| 旧BepInEx | `6.0.0-be.692` |
| 動作版 | `6.0.0-be.785` x86 Mono |
| 検証日 | 2026-08-29 |

## 1. アーカイブの安全確認

ZIPの完全性、絶対パス、`..`、外側ディレクトリ、native DLLのx86互換性、既存ファイルとの衝突を確認しました。最初のダウンロードは異なる再開方式を混在させたため中央ディレクトリが破損しました。単一ダウンローダーで再取得したZIPだけを使用しました。

上書き対象をタイムスタンプ付きディレクトリへバックアップし、マージ後にハッシュを再確認しました。DiceMasterのDLLと設定は元のハッシュを維持しました。

## 2. 古いログによる誤判定

既存`BepInEx/LogOutput.log`にはDiceMasterの記録がありました。更新日時は2024年で、Modアーカイブに含まれた履歴ログでした。

現在の起動は次の3点で判断します。

- ログ更新日時が今回の起動に一致する。
- 現在のプロセスがローカル`winhttp.dll`とPreloaderを読み込む。
- 新ログに`Chainloader initialized`と各プラグイン版が出る。

## 3. Doorstopをロードする

`Mortal.exe`のアプリケーション単位DLL overrideへ追加しました。

```text
winhttp = native,builtin
```

これによりローカル`winhttp.dll`とPreloaderがプロセスへ入りました。処理はまだChainloader前で停止し、次の障害がmanaged entry側にあることが分かりました。

## 4. 完全なUnity corlibsを使う

```text
ゲーム同梱 mscorlib.dll       3,906,048 bytes
Unity 2020.3.49 完全版        4,065,792 bytes
```

正規に入手した同一Unity版のcorlibsを`BepInEx/unstripped_corlib/`へ配置し、Doorstopを設定しました。

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

詳細ログでPreloader呼び出しと`Done`を確認しました。corlibsはUnity版を一致させ、Unityライセンスに従って取得・使用します。

## 5. BepInExのWine初期化を修復する

次の例外を捕捉しました。

```text
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

これはBepInExのWine/Proton初期化問題です。

- [issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)
- [修正PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)

旧`BepInEx/core`を丸ごと保存し、PR #1254を含むx86 Mono `6.0.0-be.785`の同一ビルド一式へ更新しました。エントリは既定の`Application::.cctor`へ戻しました。

## 6. 最終確認

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

読み込まれたプラグイン：

```text
plugin by Binarizer 1.0.0
DiceMaster 1.0.0
LOM JP Font Patch 0.2.44
LOM JP Ruby Prototype 0.15.113
LOM JP String Vault 0.1.0
```

文字列72,977行の注入と、Error/Fatalの新規発生がないことを確認しました。ゲーム内言語は簡体字中国語を選択し、`F5`で名前の振り仮名、`F7`で表示モードを切り替えます。

## 7. ロールバック

Mod導入前、corlibs設定前、`be.785`更新前の3世代を保存します。ゲーム、Windows版Steam、対象wineserverを終了してから同じレイヤーを一式で復元します。異なるBepInEx buildのcore DLLを混在させません。
